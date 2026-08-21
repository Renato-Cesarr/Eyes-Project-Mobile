import 'dart:async';

import 'package:eyes_mobile/app/app.dart';
import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:eyes_mobile/core/accessibility/accessible_feedback_service.dart';
import 'package:eyes_mobile/core/error/app_error_reporter.dart';
import 'package:eyes_mobile/core/logging/secure_logger.dart';
import 'package:eyes_mobile/features/object_detection/application/vision_frame.dart';
import 'package:eyes_mobile/features/object_detection/application/vision_worker.dart';
import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:eyes_mobile/features/proximity/application/proximity_controller.dart';
import 'package:eyes_mobile/features/scanning/application/camera_configuration.dart';
import 'package:eyes_mobile/features/scanning/application/camera_gateway.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_permission_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class _WidgetCameraGateway implements CameraGateway {
  _WidgetCameraGateway({this.permission = CameraPermissionState.granted});

  CameraPermissionState permission;
  bool streaming = false;
  int releaseCalls = 0;

  @override
  bool get isPreviewReady => streaming;

  @override
  double? get previewAspectRatio => streaming ? 4 / 3 : null;

  @override
  Future<CameraPermissionState> checkPermission() async => permission;

  @override
  Future<void> initialize(CameraConfiguration configuration) async {}

  @override
  Future<bool> openSettings() async => true;

  @override
  Future<void> release() async {
    streaming = false;
    releaseCalls++;
  }

  @override
  Future<CameraPermissionState> requestPermission() async => permission;

  @override
  Future<void> startStream({
    required CameraFrameHandler onFrame,
    required CameraTelemetryHandler onTelemetry,
    required CameraErrorHandler onError,
  }) async {
    streaming = true;
  }
}

final class _ReadyVisionWorker implements VisionWorker {
  _ReadyVisionWorker({this.startFailure});

  final VisionWorkerException? startFailure;
  final StreamController<VisionWorkerSnapshot> _snapshots =
      StreamController<VisionWorkerSnapshot>.broadcast(sync: true);

  @override
  VisionWorkerSnapshot snapshot = const VisionWorkerSnapshot.idle();
  int startCalls = 0;
  int disposeCalls = 0;

  @override
  Stream<VisionWorkerSnapshot> get snapshots => _snapshots.stream;

  @override
  Future<void> start() async {
    startCalls++;
    final failure = startFailure;
    if (failure != null) {
      snapshot = VisionWorkerSnapshot(
        phase: VisionWorkerPhase.failed,
        failure: failure,
      );
      throw failure;
    }
    snapshot = const VisionWorkerSnapshot(phase: VisionWorkerPhase.ready);
    _snapshots.add(snapshot);
  }

  @override
  Future<DetectionBatch> detect(VisionFrame frame) =>
      throw UnimplementedError();

  @override
  Future<void> dispose() async {
    disposeCalls++;
    snapshot = const VisionWorkerSnapshot.idle();
    if (!_snapshots.isClosed) {
      _snapshots.add(snapshot);
    }
  }

  Future<void> close() => _snapshots.close();
}

final class _RecordingFeedbackService implements AccessibleFeedbackService {
  int confirmations = 0;
  int warnings = 0;

  @override
  Future<void> confirm() async {
    confirmations++;
  }

  @override
  Future<void> warn() async {
    warnings++;
  }
}

void main() {
  Future<void> pumpApp(
    WidgetTester tester,
    _WidgetCameraGateway gateway, {
    _ReadyVisionWorker? worker,
    AccessibleFeedbackService? feedback,
  }) async {
    final environment = AppEnvironment.dev();
    final logger = SecureLogger(environment);
    final visionWorker = worker ?? _ReadyVisionWorker();
    addTearDown(visionWorker.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appErrorReporterProvider.overrideWithValue(AppErrorReporter(logger)),
          cameraGatewayProvider.overrideWithValue(gateway),
          visionWorkerProvider.overrideWithValue(visionWorker),
          if (feedback != null)
            accessibleFeedbackServiceProvider.overrideWithValue(feedback),
        ],
        child: const EyesApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir câmera'));
    await tester.pumpAndSettle();
  }

  testWidgets('announces permission denial and offers recovery', (
    WidgetTester tester,
  ) async {
    final gateway = _WidgetCameraGateway(
      permission: CameraPermissionState.denied,
    );
    await pumpApp(tester, gateway);

    await tester.ensureVisible(find.text('Iniciar câmera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniciar câmera'));
    await tester.pumpAndSettle();

    expect(find.text('Permissão de câmera negada.'), findsOneWidget);
    expect(
      find.text(
        'Autorize a câmera para iniciar a varredura. Você pode tentar novamente.',
      ),
      findsOneWidget,
    );
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp('Estado da varredura.*Permissão de câmera negada.'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('starts, pauses and releases a camera session', (
    WidgetTester tester,
  ) async {
    final gateway = _WidgetCameraGateway();
    final worker = _ReadyVisionWorker();
    await pumpApp(tester, gateway, worker: worker);

    await tester.ensureVisible(find.text('Iniciar câmera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniciar câmera'));
    await tester.pumpAndSettle();

    expect(
      find.text('Câmera pronta. Varredura assistiva ativa.'),
      findsOneWidget,
    );
    expect(find.text('Pausar câmera'), findsOneWidget);
    expect(find.text('Encerrar câmera'), findsOneWidget);

    await tester.ensureVisible(find.text('Pausar câmera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pausar câmera'));
    await tester.pumpAndSettle();

    expect(find.text('Câmera pausada e recursos liberados.'), findsOneWidget);
    expect(find.text('Retomar câmera'), findsOneWidget);
    expect(gateway.releaseCalls, 1);
    expect(worker.disposeCalls, 1);
  });

  testWidgets('remains usable with 200 percent text scaling', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final gateway = _WidgetCameraGateway();

    await pumpApp(tester, gateway);
    await tester.ensureVisible(find.text('Iniciar câmera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniciar câmera'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Pausar câmera'), findsOneWidget);
  });

  testWidgets('TalkBack receives only a temporally stabilized alert', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, _WidgetCameraGateway());
    await tester.ensureVisible(find.text('Iniciar câmera'));
    await tester.tap(find.text('Iniciar câmera'));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.text('Câmera pronta. Varredura assistiva ativa.')),
    );
    final controller = container.read(proximityControllerProvider.notifier);

    controller.process(_detectionBatch(0));
    await tester.pump();
    expect(find.text('Cadeira muito próxima. Cuidado.'), findsNothing);

    controller.process(_detectionBatch(1));
    controller.process(_detectionBatch(2));
    await tester.pump();

    expect(find.text('Cadeira muito próxima. Cuidado.'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Cadeira muito próxima. Cuidado.'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp(r'FPS|threshold|tensor|\d+\s*ms')),
      findsNothing,
    );
    await tester.ensureVisible(find.text('Pausar câmera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pausar câmera'));
    await tester.pumpAndSettle();
    expect(find.text('Cadeira muito próxima. Cuidado.'), findsNothing);
    expect(container.read(proximityControllerProvider).lastAlert, isNull);
    semantics.dispose();
  });

  testWidgets('exposes a sanitized AI failure to TalkBack and haptics', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final feedback = _RecordingFeedbackService();
    final worker = _ReadyVisionWorker(
      startFailure: const VisionWorkerException(
        VisionWorkerFailureReason.initialization,
        'native interpreter allocation payload',
        technicalCode: 'interpreter-allocation-failed-42ms',
      ),
    );

    await pumpApp(
      tester,
      _WidgetCameraGateway(),
      worker: worker,
      feedback: feedback,
    );

    expect(
      find.text('Erro ao iniciar inteligência artificial.'),
      findsOneWidget,
    );
    expect(find.textContaining('interpreter-allocation'), findsNothing);
    expect(
      find.bySemanticsLabel(
        RegExp('Estado da varredura: Erro ao iniciar inteligência artificial.'),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp(r'FPS|threshold|\d+\s*ms')),
      findsNothing,
    );
    expect(feedback.warnings, 1);
    semantics.dispose();
  });
}

DetectionBatch _detectionBatch(int second) {
  return DetectionBatch(
    detections: [
      DetectedObject(
        kind: DetectedObjectKind.chair,
        confidence: 0.9,
        boundingBox: NormalizedBoundingBox(
          top: 0.05,
          left: 0.20,
          bottom: 0.98,
          right: 0.80,
        ),
      ),
    ],
    capturedAt: DateTime.utc(2026).add(Duration(seconds: second)),
    timings: const DetectionTimings(
      preprocessing: Duration.zero,
      inference: Duration.zero,
      postprocessing: Duration.zero,
    ),
  );
}
