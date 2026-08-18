import 'dart:async';

import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:eyes_mobile/core/error/app_error_reporter.dart';
import 'package:eyes_mobile/core/logging/secure_logger.dart';
import 'package:eyes_mobile/features/scanning/application/camera_configuration.dart';
import 'package:eyes_mobile/features/scanning/application/camera_gateway.dart';
import 'package:eyes_mobile/features/scanning/application/scan_controller.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_permission_state.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_scan_status.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_telemetry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeCameraGateway implements CameraGateway {
  CameraPermissionState permission = CameraPermissionState.granted;
  CameraPermissionState requestedPermission = CameraPermissionState.granted;
  CameraGatewayException? initializationError;
  Completer<void>? initializationGate;
  CameraTelemetryHandler? telemetryHandler;
  CameraErrorHandler? errorHandler;
  int checkPermissionCalls = 0;
  int requestPermissionCalls = 0;
  int initializeCalls = 0;
  int startStreamCalls = 0;
  int releaseCalls = 0;
  int openSettingsCalls = 0;

  @override
  bool get isPreviewReady => startStreamCalls > releaseCalls;

  @override
  double? get previewAspectRatio => isPreviewReady ? 16 / 9 : null;

  @override
  Future<CameraPermissionState> checkPermission() async {
    checkPermissionCalls++;
    return permission;
  }

  @override
  Future<void> initialize(CameraConfiguration configuration) async {
    initializeCalls++;
    final error = initializationError;
    if (error != null) {
      throw error;
    }
    await (initializationGate?.future ?? Future<void>.value());
  }

  @override
  Future<bool> openSettings() async {
    openSettingsCalls++;
    return true;
  }

  @override
  Future<void> release() async => releaseCalls++;

  @override
  Future<CameraPermissionState> requestPermission() async {
    requestPermissionCalls++;
    return requestedPermission;
  }

  @override
  Future<void> startStream({
    required CameraFrameHandler onFrame,
    required CameraTelemetryHandler onTelemetry,
    required CameraErrorHandler onError,
  }) async {
    startStreamCalls++;
    telemetryHandler = onTelemetry;
    errorHandler = onError;
  }
}

void main() {
  ProviderContainer createContainer(
    _FakeCameraGateway gateway, {
    CameraConfiguration configuration = const CameraConfiguration(),
  }) {
    final logger = SecureLogger(AppEnvironment.dev());
    return ProviderContainer(
      overrides: [
        cameraGatewayProvider.overrideWithValue(gateway),
        cameraConfigurationProvider.overrideWithValue(configuration),
        appErrorReporterProvider.overrideWithValue(AppErrorReporter(logger)),
      ],
    );
  }

  test('starts preview and stream after permission is granted', () async {
    final gateway = _FakeCameraGateway();
    final container = createContainer(gateway);
    addTearDown(container.dispose);
    await container.read(scanControllerProvider.future);

    await container.read(scanControllerProvider.notifier).start();
    final session = container.read(scanControllerProvider).requireValue;

    expect(session.status, CameraScanStatus.streaming);
    expect(session.previewAspectRatio, closeTo(16 / 9, 0.001));
    expect(gateway.initializeCalls, 1);
    expect(gateway.startStreamCalls, 1);
  });

  test('exposes temporary permission denial without initializing', () async {
    final gateway = _FakeCameraGateway()
      ..permission = CameraPermissionState.denied
      ..requestedPermission = CameraPermissionState.denied;
    final container = createContainer(gateway);
    addTearDown(container.dispose);
    await container.read(scanControllerProvider.future);

    await container.read(scanControllerProvider.notifier).start();

    expect(
      container.read(scanControllerProvider).requireValue.status,
      CameraScanStatus.denied,
    );
    expect(gateway.requestPermissionCalls, 1);
    expect(gateway.initializeCalls, 0);
  });

  test('exposes permanent permission denial and opens settings', () async {
    final gateway = _FakeCameraGateway()
      ..permission = CameraPermissionState.permanentlyDenied;
    final container = createContainer(gateway);
    addTearDown(container.dispose);
    await container.read(scanControllerProvider.future);
    final controller = container.read(scanControllerProvider.notifier);

    await controller.start();
    final opened = await controller.openSettings();

    expect(
      container.read(scanControllerProvider).requireValue.status,
      CameraScanStatus.permanentlyDenied,
    );
    expect(opened, isTrue);
    expect(gateway.openSettingsCalls, 1);
  });

  test('maps a busy native camera to a recoverable state', () async {
    final gateway = _FakeCameraGateway()
      ..initializationError = const CameraGatewayException(
        CameraGatewayFailureReason.busy,
        code: 'camera-in-use',
      );
    final container = createContainer(gateway);
    addTearDown(container.dispose);
    await container.read(scanControllerProvider.future);

    await container.read(scanControllerProvider.notifier).start();

    expect(
      container.read(scanControllerProvider).requireValue.status,
      CameraScanStatus.busy,
    );
    expect(gateway.releaseCalls, 1);
  });

  test('times out initialization and releases camera resources', () async {
    final initializationGate = Completer<void>();
    final gateway = _FakeCameraGateway()
      ..initializationGate = initializationGate;
    final container = createContainer(
      gateway,
      configuration: const CameraConfiguration(
        initializationTimeout: Duration(milliseconds: 5),
      ),
    );
    addTearDown(() {
      if (!initializationGate.isCompleted) {
        initializationGate.complete();
      }
      container.dispose();
    });
    await container.read(scanControllerProvider.future);

    await container.read(scanControllerProvider.notifier).start();

    expect(
      container.read(scanControllerProvider).requireValue.status,
      CameraScanStatus.unavailable,
    );
    expect(gateway.releaseCalls, 1);
  });

  test(
    'pause releases resources and resume initializes a new session',
    () async {
      final gateway = _FakeCameraGateway();
      final container = createContainer(gateway);
      addTearDown(container.dispose);
      await container.read(scanControllerProvider.future);
      final controller = container.read(scanControllerProvider.notifier);

      await controller.start();
      await controller.pause();
      expect(
        container.read(scanControllerProvider).requireValue.status,
        CameraScanStatus.paused,
      );
      expect(gateway.releaseCalls, 1);

      await controller.resume();
      expect(
        container.read(scanControllerProvider).requireValue.status,
        CameraScanStatus.streaming,
      );
      expect(gateway.initializeCalls, 2);
    },
  );

  test(
    'background releases camera and foreground restores active scanning',
    () async {
      final gateway = _FakeCameraGateway();
      final container = createContainer(gateway);
      addTearDown(container.dispose);
      await container.read(scanControllerProvider.future);
      final controller = container.read(scanControllerProvider.notifier);

      await controller.start();
      await controller.handleBackground();
      expect(
        container.read(scanControllerProvider).requireValue.status,
        CameraScanStatus.paused,
      );

      await controller.handleForeground();
      expect(
        container.read(scanControllerProvider).requireValue.status,
        CameraScanStatus.streaming,
      );
      expect(gateway.initializeCalls, 2);
    },
  );

  test('publishes local telemetry while streaming', () async {
    final gateway = _FakeCameraGateway();
    final container = createContainer(gateway);
    addTearDown(container.dispose);
    await container.read(scanControllerProvider.future);
    await container.read(scanControllerProvider.notifier).start();

    gateway.telemetryHandler!(
      const CameraTelemetry(
        receivedFrames: 20,
        processedFrames: 12,
        droppedFrames: 7,
        framesPerSecond: 11.8,
        lastProcessingTime: Duration(milliseconds: 9),
      ),
    );

    final telemetry = container
        .read(scanControllerProvider)
        .requireValue
        .telemetry;
    expect(telemetry.receivedFrames, 20);
    expect(telemetry.processedFrames, 12);
    expect(telemetry.droppedFrames, 7);
  });

  test('runtime stream failure never leaves a false streaming state', () async {
    final gateway = _FakeCameraGateway();
    final container = createContainer(gateway);
    addTearDown(container.dispose);
    await container.read(scanControllerProvider.future);
    await container.read(scanControllerProvider.notifier).start();

    gateway.errorHandler!(
      const CameraGatewayException(
        CameraGatewayFailureReason.stream,
        code: 'stream-failed',
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(scanControllerProvider).requireValue.status,
      CameraScanStatus.unavailable,
    );
    expect(gateway.releaseCalls, 1);
  });
}
