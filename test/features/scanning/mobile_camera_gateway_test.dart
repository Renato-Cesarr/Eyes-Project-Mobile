import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:eyes_mobile/features/scanning/application/camera_configuration.dart';
import 'package:eyes_mobile/features/scanning/application/camera_gateway.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_frame.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_permission_state.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_telemetry.dart';
import 'package:eyes_mobile/features/scanning/infrastructure/mobile_camera_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

final class _FakePermissionDriver implements CameraPermissionDriver {
  PermissionStatus current = PermissionStatus.granted;
  PermissionStatus requested = PermissionStatus.granted;
  bool settingsResult = true;
  int checkCalls = 0;
  int requestCalls = 0;
  int settingsCalls = 0;

  @override
  Future<PermissionStatus> check() async {
    checkCalls++;
    return current;
  }

  @override
  Future<bool> openSettings() async {
    settingsCalls++;
    return settingsResult;
  }

  @override
  Future<PermissionStatus> request() async {
    requestCalls++;
    return requested;
  }
}

final class _FakeCameraPluginDriver implements CameraPluginDriver {
  _FakeCameraPluginDriver({required this.cameras, required this.controller});

  List<CameraDescription> cameras;
  final _FakeCameraDeviceController controller;
  Object? availableError;
  CameraDescription? selectedDescription;
  ResolutionPreset? selectedResolution;
  int? selectedFramesPerSecond;

  @override
  Future<List<CameraDescription>> available() async {
    final error = availableError;
    if (error != null) {
      throw error;
    }
    return cameras;
  }

  @override
  CameraDeviceController createController({
    required CameraDescription description,
    required ResolutionPreset resolution,
    required int framesPerSecond,
  }) {
    selectedDescription = description;
    selectedResolution = resolution;
    selectedFramesPerSecond = framesPerSecond;
    controller.configuredFramesPerSecondValue = framesPerSecond;
    return controller;
  }
}

final class _FakeCameraDeviceController implements CameraDeviceController {
  bool initialized = false;
  bool streaming = false;
  bool errorState = false;
  double previewAspectRatio = 4 / 3;
  int? configuredFramesPerSecondValue;
  Object? initializationError;
  Object? streamStartError;
  Object? stopError;
  Object? disposeError;
  int initializeCalls = 0;
  int startCalls = 0;
  int stopCalls = 0;
  int disposeCalls = 0;
  void Function(CameraImage image)? imageCallback;
  final List<void Function()> listeners = <void Function()>[];

  @override
  double get aspectRatio => previewAspectRatio;

  @override
  int? get configuredFramesPerSecond => configuredFramesPerSecondValue;

  @override
  bool get hasError => errorState;

  @override
  bool get isInitialized => initialized;

  @override
  bool get isStreamingImages => streaming;

  @override
  CameraController? get previewController => null;

  @override
  void addListener(void Function() listener) => listeners.add(listener);

  @override
  Future<void> dispose() async {
    disposeCalls++;
    initialized = false;
    final error = disposeError;
    if (error != null) {
      throw error;
    }
  }

  void emit(CameraImage image) => imageCallback?.call(image);

  void emitNativeError() {
    errorState = true;
    for (final listener in List<void Function()>.of(listeners)) {
      listener();
    }
  }

  @override
  Future<void> initialize() async {
    initializeCalls++;
    final error = initializationError;
    if (error != null) {
      throw error;
    }
    initialized = true;
  }

  @override
  void removeListener(void Function() listener) => listeners.remove(listener);

  @override
  Future<void> startImageStream(
    void Function(CameraImage image) onImage,
  ) async {
    startCalls++;
    final error = streamStartError;
    if (error != null) {
      throw error;
    }
    imageCallback = onImage;
    streaming = true;
  }

  @override
  Future<void> stopImageStream() async {
    stopCalls++;
    streaming = false;
    final error = stopError;
    if (error != null) {
      throw error;
    }
  }
}

void main() {
  const frontCamera = CameraDescription(
    name: 'front',
    lensDirection: CameraLensDirection.front,
    sensorOrientation: 90,
  );
  const backCamera = CameraDescription(
    name: 'back',
    lensDirection: CameraLensDirection.back,
    sensorOrientation: 90,
  );

  ({MobileCameraGateway gateway, _FakeCameraPluginDriver plugin})
  createGateway({
    _FakePermissionDriver? permission,
    _FakeCameraDeviceController? controller,
    List<CameraDescription> cameras = const <CameraDescription>[
      frontCamera,
      backCamera,
    ],
    DateTime Function()? clock,
  }) {
    final deviceController = controller ?? _FakeCameraDeviceController();
    final plugin = _FakeCameraPluginDriver(
      cameras: cameras,
      controller: deviceController,
    );
    return (
      gateway: MobileCameraGateway(
        cameraDriver: plugin,
        permissionDriver: permission ?? _FakePermissionDriver(),
        clock: clock ?? DateTime.now,
      ),
      plugin: plugin,
    );
  }

  test(
    'maps every permission state and opens settings through its driver',
    () async {
      final permission = _FakePermissionDriver();
      final setup = createGateway(permission: permission);
      const expected = <PermissionStatus, CameraPermissionState>{
        PermissionStatus.granted: CameraPermissionState.granted,
        PermissionStatus.provisional: CameraPermissionState.granted,
        PermissionStatus.denied: CameraPermissionState.denied,
        PermissionStatus.permanentlyDenied:
            CameraPermissionState.permanentlyDenied,
        PermissionStatus.restricted: CameraPermissionState.restricted,
        PermissionStatus.limited: CameraPermissionState.restricted,
      };

      for (final entry in expected.entries) {
        permission.current = entry.key;
        permission.requested = entry.key;
        expect(await setup.gateway.checkPermission(), entry.value);
        expect(await setup.gateway.requestPermission(), entry.value);
      }
      expect(await setup.gateway.openSettings(), isTrue);
      expect(permission.checkCalls, expected.length);
      expect(permission.requestCalls, expected.length);
      expect(permission.settingsCalls, 1);
    },
  );

  test(
    'selects the rear camera with the configured resolution and FPS',
    () async {
      final setup = createGateway();

      await setup.gateway.initialize(
        const CameraConfiguration(
          resolution: CameraResolution.medium,
          targetFramesPerSecond: 12,
        ),
      );

      expect(setup.plugin.selectedDescription, backCamera);
      expect(setup.plugin.selectedResolution, ResolutionPreset.medium);
      expect(setup.plugin.selectedFramesPerSecond, 12);
      expect(setup.gateway.isPreviewReady, isTrue);
      expect(setup.gateway.previewAspectRatio, closeTo(4 / 3, 0.001));
      expect(setup.gateway.previewController, isNull);
      await setup.gateway.release();
    },
  );

  test('falls back to the first camera when no rear lens exists', () async {
    final setup = createGateway(
      cameras: const <CameraDescription>[frontCamera],
    );

    await setup.gateway.initialize(const CameraConfiguration());

    expect(setup.plugin.selectedDescription, frontCamera);
    await setup.gateway.release();
  });

  test('reports a missing camera without creating a controller', () async {
    final setup = createGateway(cameras: const <CameraDescription>[]);

    await expectLater(
      setup.gateway.initialize(const CameraConfiguration()),
      throwsA(
        isA<CameraGatewayException>().having(
          (CameraGatewayException error) => error.reason,
          'reason',
          CameraGatewayFailureReason.noCamera,
        ),
      ),
    );
    expect(setup.plugin.selectedDescription, isNull);
  });

  test(
    'maps native initialization failures and releases the controller',
    () async {
      final cases = <CameraException, CameraGatewayFailureReason>{
        CameraException('CameraAccessDenied', 'denied'):
            CameraGatewayFailureReason.permissionDenied,
        CameraException('CameraAccessDeniedWithoutPrompt', 'permanently'):
            CameraGatewayFailureReason.permissionPermanentlyDenied,
        CameraException('CameraAccessRestricted', 'restricted'):
            CameraGatewayFailureReason.permissionRestricted,
        CameraException('CameraAccess', 'camera in use'):
            CameraGatewayFailureReason.busy,
        CameraException('other', 'vendor failure'):
            CameraGatewayFailureReason.initialization,
      };

      for (final entry in cases.entries) {
        final controller = _FakeCameraDeviceController()
          ..initializationError = entry.key;
        final setup = createGateway(controller: controller);
        await expectLater(
          setup.gateway.initialize(const CameraConfiguration()),
          throwsA(
            isA<CameraGatewayException>().having(
              (CameraGatewayException error) => error.reason,
              'reason',
              entry.value,
            ),
          ),
        );
        expect(controller.disposeCalls, 1);
      }
    },
  );

  test('sanitizes an unexpected initialization failure', () async {
    final controller = _FakeCameraDeviceController()
      ..initializationError = StateError('native payload');
    final setup = createGateway(controller: controller);

    await expectLater(
      setup.gateway.initialize(const CameraConfiguration()),
      throwsA(
        isA<CameraGatewayException>()
            .having(
              (CameraGatewayException error) => error.reason,
              'reason',
              CameraGatewayFailureReason.initialization,
            )
            .having(
              (CameraGatewayException error) => error.code,
              'code',
              'initialization-failed',
            ),
      ),
    );
    expect(controller.disposeCalls, 1);
  });

  test('requires initialization before starting the image stream', () async {
    final setup = createGateway();

    await expectLater(
      setup.gateway.startStream(
        onFrame: (CameraFrame frame) async {},
        onTelemetry: (CameraTelemetry telemetry) {},
        onError: (CameraGatewayException error) {},
      ),
      throwsA(
        isA<CameraGatewayException>().having(
          (CameraGatewayException error) => error.code,
          'code',
          'camera-not-initialized',
        ),
      ),
    );
  });

  test(
    'converts native images and publishes non-sensitive telemetry',
    () async {
      var now = DateTime.utc(2026);
      final setup = createGateway(clock: () => now);
      final frames = <CameraFrame>[];
      final telemetry = <CameraTelemetry>[];
      final errors = <CameraGatewayException>[];
      await setup.gateway.initialize(const CameraConfiguration());
      await setup.gateway.startStream(
        onFrame: (CameraFrame frame) async {
          frames.add(frame);
          now = now.add(const Duration(milliseconds: 8));
        },
        onTelemetry: telemetry.add,
        onError: errors.add,
      );

      now = now.add(const Duration(milliseconds: 600));
      setup.plugin.controller.emit(_cameraImage(width: 4));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await setup.gateway.release();

      expect(frames, hasLength(1));
      expect(frames.single.width, 4);
      expect(frames.single.height, 2);
      expect(frames.single.format, CameraPixelFormat.nv21);
      expect(frames.single.planes.single.bytes, <int>[1, 2, 3, 4]);
      expect(
        () => frames.single.planes.single.bytes[0] = 9,
        throwsUnsupportedError,
      );
      expect(telemetry.last.receivedFrames, 1);
      expect(telemetry.last.processedFrames, 1);
      expect(
        telemetry.last.lastProcessingTime,
        const Duration(milliseconds: 8),
      );
      expect(errors, isEmpty);
    },
  );

  test(
    'reports a frame consumer failure without exposing its payload',
    () async {
      final now = DateTime.utc(2026);
      final setup = createGateway(clock: () => now);
      final errors = <CameraGatewayException>[];
      await setup.gateway.initialize(const CameraConfiguration());
      await setup.gateway.startStream(
        onFrame: (CameraFrame frame) async =>
            throw StateError('private payload'),
        onTelemetry: (CameraTelemetry telemetry) {},
        onError: errors.add,
      );

      setup.plugin.controller.emit(_cameraImage(width: 2));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(errors, hasLength(1));
      expect(errors.single.reason, CameraGatewayFailureReason.stream);
      expect(errors.single.code, 'frame-consumer-failed');
      await setup.gateway.release();
    },
  );

  test('reports a native runtime error only once', () async {
    final setup = createGateway();
    final errors = <CameraGatewayException>[];
    await setup.gateway.initialize(const CameraConfiguration());
    await setup.gateway.startStream(
      onFrame: (CameraFrame frame) async {},
      onTelemetry: (CameraTelemetry telemetry) {},
      onError: errors.add,
    );

    setup.plugin.controller.emitNativeError();
    setup.plugin.controller.emitNativeError();

    expect(errors, hasLength(1));
    expect(errors.single.code, 'native-camera-error');
    await setup.gateway.release();
  });

  test('maps stream startup errors and closes its processor', () async {
    final controller = _FakeCameraDeviceController()
      ..streamStartError = CameraException('stream', 'failed');
    final setup = createGateway(controller: controller);
    await setup.gateway.initialize(const CameraConfiguration());

    await expectLater(
      setup.gateway.startStream(
        onFrame: (CameraFrame frame) async {},
        onTelemetry: (CameraTelemetry telemetry) {},
        onError: (CameraGatewayException error) {},
      ),
      throwsA(
        isA<CameraGatewayException>().having(
          (CameraGatewayException error) => error.reason,
          'reason',
          CameraGatewayFailureReason.stream,
        ),
      ),
    );
    await setup.gateway.release();
  });

  test('release remains idempotent when native cleanup fails', () async {
    final controller = _FakeCameraDeviceController()
      ..stopError = StateError('stop failed')
      ..disposeError = StateError('dispose failed');
    final setup = createGateway(controller: controller);
    await setup.gateway.initialize(const CameraConfiguration());
    await setup.gateway.startStream(
      onFrame: (CameraFrame frame) async {},
      onTelemetry: (CameraTelemetry telemetry) {},
      onError: (CameraGatewayException error) {},
    );

    await setup.gateway.release();
    await setup.gateway.release();

    expect(controller.stopCalls, 1);
    expect(controller.disposeCalls, 1);
    expect(setup.gateway.isPreviewReady, isFalse);
  });
}

CameraImage _cameraImage({required int width}) {
  return CameraImage.fromPlatformInterface(
    CameraImageData(
      format: const CameraImageFormat(ImageFormatGroup.nv21, raw: 17),
      planes: <CameraImagePlane>[
        CameraImagePlane(
          bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
          bytesPerRow: width,
          bytesPerPixel: 1,
        ),
      ],
      height: 2,
      width: width,
    ),
  );
}
