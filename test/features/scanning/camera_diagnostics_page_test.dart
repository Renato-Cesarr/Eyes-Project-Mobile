import 'package:eyes_mobile/app/app.dart';
import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:eyes_mobile/core/error/app_error_reporter.dart';
import 'package:eyes_mobile/core/logging/secure_logger.dart';
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

void main() {
  Future<void> pumpApp(
    WidgetTester tester,
    _WidgetCameraGateway gateway,
  ) async {
    final environment = AppEnvironment.dev();
    final logger = SecureLogger(environment);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appErrorReporterProvider.overrideWithValue(AppErrorReporter(logger)),
          cameraGatewayProvider.overrideWithValue(gateway),
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
        RegExp('Estado da câmera.*Permissão de câmera negada.'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('starts, pauses and releases a camera session', (
    WidgetTester tester,
  ) async {
    final gateway = _WidgetCameraGateway();
    await pumpApp(tester, gateway);

    await tester.ensureVisible(find.text('Iniciar câmera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniciar câmera'));
    await tester.pumpAndSettle();

    expect(find.text('Câmera ativa e recebendo imagens.'), findsOneWidget);
    expect(find.text('Pausar câmera'), findsOneWidget);
    expect(find.text('Encerrar câmera'), findsOneWidget);

    await tester.ensureVisible(find.text('Pausar câmera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pausar câmera'));
    await tester.pumpAndSettle();

    expect(find.text('Câmera pausada e recursos liberados.'), findsOneWidget);
    expect(find.text('Retomar câmera'), findsOneWidget);
    expect(gateway.releaseCalls, 1);
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
}
