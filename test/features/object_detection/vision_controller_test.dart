import 'dart:async';
import 'dart:typed_data';

import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:eyes_mobile/core/error/app_error_reporter.dart';
import 'package:eyes_mobile/core/logging/secure_logger.dart';
import 'package:eyes_mobile/features/object_detection/application/vision_controller.dart';
import 'package:eyes_mobile/features/object_detection/application/vision_frame.dart';
import 'package:eyes_mobile/features/object_detection/application/vision_runtime_state.dart';
import 'package:eyes_mobile/features/object_detection/application/vision_worker.dart';
import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProviderContainer createContainer(_FakeVisionWorker worker) {
    return ProviderContainer(
      overrides: [
        visionWorkerProvider.overrideWithValue(worker),
        appErrorReporterProvider.overrideWithValue(
          AppErrorReporter(SecureLogger(AppEnvironment.dev())),
        ),
      ],
    );
  }

  test('expõe loading e ready sem acoplar a UI ao worker', () async {
    final gate = Completer<void>();
    final worker = _FakeVisionWorker(startGate: gate);
    final container = createContainer(worker);
    addTearDown(() async {
      container.dispose();
      await worker.close();
    });

    final future = container.read(visionControllerProvider.future);
    expect(
      container.read(visionControllerProvider),
      isA<AsyncLoading<VisionRuntimeState>>(),
    );
    gate.complete();
    await future;

    expect(
      container.read(visionControllerProvider).requireValue.status,
      VisionRuntimeStatus.ready,
    );
    expect(worker.startCalls, 1);
  });

  test('publica somente entidades de detecção processadas', () async {
    final worker = _FakeVisionWorker();
    final container = createContainer(worker);
    addTearDown(() async {
      container.dispose();
      await worker.close();
    });
    await container.read(visionControllerProvider.future);

    final result = await container
        .read(visionControllerProvider.notifier)
        .process(_frame());

    final state = container.read(visionControllerProvider).requireValue;
    expect(result.detections.single.kind, DetectedObjectKind.chair);
    expect(state.lastDetection, same(result));
    expect(state.processedFrames, 1);
  });

  test('background libera runtime e foreground cria outro', () async {
    final worker = _FakeVisionWorker();
    final container = createContainer(worker);
    addTearDown(() async {
      container.dispose();
      await worker.close();
    });
    await container.read(visionControllerProvider.future);
    final controller = container.read(visionControllerProvider.notifier);

    await controller.handleBackground();
    expect(worker.disposeCalls, 1);
    expect(
      container.read(visionControllerProvider).requireValue.status,
      VisionRuntimeStatus.paused,
    );

    await controller.handleForeground();
    expect(worker.startCalls, 2);
    expect(
      container.read(visionControllerProvider).requireValue.status,
      VisionRuntimeStatus.ready,
    );
  });

  test('encerrar a tela libera runtime e permite uma nova sessão', () async {
    final worker = _FakeVisionWorker();
    final container = createContainer(worker);
    addTearDown(() async {
      container.dispose();
      await worker.close();
    });
    await container.read(visionControllerProvider.future);
    final controller = container.read(visionControllerProvider.notifier);

    await controller.stop();
    expect(worker.disposeCalls, 1);
    expect(
      container.read(visionControllerProvider).requireValue.status,
      VisionRuntimeStatus.paused,
    );

    await controller.start();
    expect(worker.startCalls, 2);
    expect(
      container.read(visionControllerProvider).requireValue.status,
      VisionRuntimeStatus.ready,
    );
  });

  test('falha assíncrona do isolate transita Riverpod para error', () async {
    final worker = _FakeVisionWorker();
    final container = createContainer(worker);
    addTearDown(() async {
      container.dispose();
      await worker.close();
    });
    await container.read(visionControllerProvider.future);

    worker.fail(
      const VisionWorkerException(
        VisionWorkerFailureReason.isolateCrashed,
        'Falha controlada.',
        technicalCode: 'fake-crash',
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final state = container.read(visionControllerProvider);
    expect(state, isA<AsyncError<VisionRuntimeState>>());
    expect(state.error, isA<VisionWorkerException>());
  });
}

VisionFrame _frame() => VisionFrame(
  width: 2,
  height: 2,
  format: VisionPixelFormat.nv21,
  planes: [
    VisionFramePlane(
      bytes: Uint8List.fromList([16, 16, 16, 16, 128, 128]),
      bytesPerRow: 2,
      bytesPerPixel: 1,
    ),
  ],
  rotation: VisionRotation.degrees0,
  capturedAt: DateTime.utc(2026),
);

final class _FakeVisionWorker implements VisionWorker {
  _FakeVisionWorker({this.startGate});

  final Completer<void>? startGate;
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
    snapshot = const VisionWorkerSnapshot(phase: VisionWorkerPhase.starting);
    _snapshots.add(snapshot);
    await (startGate?.future ?? Future<void>.value());
    snapshot = const VisionWorkerSnapshot(phase: VisionWorkerPhase.ready);
    _snapshots.add(snapshot);
  }

  @override
  Future<DetectionBatch> detect(VisionFrame frame) async {
    return DetectionBatch(
      detections: [
        DetectedObject(
          kind: DetectedObjectKind.chair,
          confidence: 0.8,
          boundingBox: NormalizedBoundingBox(
            top: 0.1,
            left: 0.2,
            bottom: 0.8,
            right: 0.9,
          ),
        ),
      ],
      capturedAt: frame.capturedAt,
      timings: const DetectionTimings(
        preprocessing: Duration(milliseconds: 1),
        inference: Duration(milliseconds: 10),
        postprocessing: Duration(milliseconds: 1),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
    snapshot = const VisionWorkerSnapshot.idle();
    _snapshots.add(snapshot);
  }

  void fail(VisionWorkerException failure) {
    snapshot = VisionWorkerSnapshot(
      phase: VisionWorkerPhase.failed,
      failure: failure,
    );
    _snapshots.add(snapshot);
  }

  Future<void> close() => _snapshots.close();
}
