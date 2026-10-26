import 'dart:async';

import 'package:eyes_mobile/features/scanning/application/camera_configuration.dart';
import 'package:eyes_mobile/features/scanning/application/camera_gateway.dart';
import 'package:eyes_mobile/features/scanning/application/camera_source.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_permission_state.dart';
import 'package:eyes_mobile/features/scanning/infrastructure/selectable_camera_gateway.dart';
import 'package:eyes_mobile/features/scanning/infrastructure/uvc_camera_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

final class _MemoryPreferenceStore implements CameraSourcePreferenceStore {
  CameraSourceKind? saved;

  @override
  Future<CameraSourceKind?> load() async => saved;

  @override
  Future<void> save(CameraSourceKind kind) async => saved = kind;
}

class _FakeCamera implements CameraGateway {
  CameraConfiguration? configuration;
  CameraGatewayException? initializationFailure;
  int releases = 0;
  int streamStarts = 0;

  @override
  bool get isPreviewReady => configuration != null;

  @override
  double? get previewAspectRatio => isPreviewReady ? 4 / 3 : null;

  @override
  Future<CameraPermissionState> checkPermission() async =>
      CameraPermissionState.granted;

  @override
  Future<CameraPermissionState> requestPermission() async =>
      CameraPermissionState.granted;

  @override
  Future<bool> openSettings() async => true;

  @override
  Future<void> initialize(CameraConfiguration configuration) async {
    final failure = initializationFailure;
    if (failure != null) throw failure;
    this.configuration = configuration;
  }

  @override
  Future<void> startStream({
    required CameraFrameHandler onFrame,
    required CameraTelemetryHandler onTelemetry,
    required CameraErrorHandler onError,
  }) async => streamStarts++;

  @override
  Future<void> release() async {
    releases++;
    configuration = null;
  }
}

final class _FakeWebcam extends _FakeCamera implements WebcamCameraGateway {
  final StreamController<Object?> events =
      StreamController<Object?>.broadcast();
  List<WebcamDevice> devices = [];
  bool discoveryFails = false;
  bool disposed = false;

  @override
  Stream<Object?> get deviceEvents => events.stream;

  @override
  int? get previewTextureId => 7;

  @override
  Future<List<WebcamDevice>> discover() async {
    if (discoveryFails) throw StateError('USB enumeration failed');
    return devices;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await events.close();
  }
}

void main() {
  const webcam = WebcamDevice(id: 42, name: 'Webcam UVC');

  test('prefers attached USB camera by default and releases it', () async {
    final phone = _FakeCamera();
    final usb = _FakeWebcam()..devices = [webcam];
    final gateway = SelectableCameraGateway(
      phone,
      usb,
      _MemoryPreferenceStore(),
    );
    addTearDown(gateway.dispose);

    await gateway.initialize(const CameraConfiguration());

    expect(gateway.sourceState.active, CameraSourceKind.webcam);
    expect(usb.configuration?.webcamDeviceId, 42);
    expect(phone.configuration, isNull);
    await gateway.release();
    expect(usb.releases, 1);
    expect(gateway.sourceState.active, isNull);
  });

  test('manual phone selection persists when USB is connected', () async {
    final phone = _FakeCamera();
    final usb = _FakeWebcam()..devices = [webcam];
    final store = _MemoryPreferenceStore();
    final gateway = SelectableCameraGateway(phone, usb, store);
    addTearDown(gateway.dispose);

    await gateway.selectSource(CameraSourceKind.phone);
    await gateway.initialize(const CameraConfiguration());

    expect(store.saved, CameraSourceKind.phone);
    expect(gateway.sourceState.active, CameraSourceKind.phone);
    expect(phone.configuration?.source, CameraSourceKind.phone);
    expect(usb.configuration, isNull);
    await gateway.startStream(
      onFrame: (_) async {},
      onTelemetry: (_) {},
      onError: (_) {},
    );
    expect(phone.streamStarts, 1);
    expect(usb.streamStarts, 0);
  });

  test(
    'falls back to phone only when no explicit USB preference exists',
    () async {
      final phone = _FakeCamera();
      final usb = _FakeWebcam();
      final store = _MemoryPreferenceStore();
      final gateway = SelectableCameraGateway(phone, usb, store);
      addTearDown(gateway.dispose);

      await gateway.initialize(const CameraConfiguration());
      expect(gateway.sourceState.active, CameraSourceKind.phone);

      await gateway.selectSource(CameraSourceKind.webcam);
      await gateway.release();
      await expectLater(
        gateway.initialize(const CameraConfiguration()),
        throwsA(
          isA<CameraGatewayException>().having(
            (error) => error.code,
            'code',
            'webcam-not-connected',
          ),
        ),
      );
      expect(gateway.sourceState.preference, CameraSourceKind.webcam);
    },
  );

  test(
    'unusable USB falls back before streaming with an explicit notice',
    () async {
      final phone = _FakeCamera();
      final usb = _FakeWebcam()
        ..devices = [webcam]
        ..initializationFailure = const CameraGatewayException(
          CameraGatewayFailureReason.initialization,
          code: 'webcam-no-valid-video-mode',
        );
      final gateway = SelectableCameraGateway(
        phone,
        usb,
        _MemoryPreferenceStore(),
      );
      addTearDown(gateway.dispose);

      await gateway.initialize(const CameraConfiguration());

      expect(gateway.sourceState.active, CameraSourceKind.phone);
      expect(gateway.sourceState.selected, CameraSourceKind.phone);
      expect(gateway.sourceState.fellBackToPhone, isTrue);
      expect(phone.configuration?.source, CameraSourceKind.phone);
      expect(usb.releases, 1);
    },
  );

  test(
    'explicit USB choice reports startup failure instead of switching',
    () async {
      final phone = _FakeCamera();
      final usb = _FakeWebcam()
        ..devices = [webcam]
        ..initializationFailure = const CameraGatewayException(
          CameraGatewayFailureReason.initialization,
          code: 'webcam-no-valid-video-mode',
        );
      final store = _MemoryPreferenceStore()..saved = CameraSourceKind.webcam;
      final gateway = SelectableCameraGateway(phone, usb, store);
      addTearDown(gateway.dispose);

      await expectLater(
        gateway.initialize(const CameraConfiguration()),
        throwsA(isA<CameraGatewayException>()),
      );

      expect(phone.configuration, isNull);
      expect(gateway.sourceState.active, isNull);
      expect(gateway.sourceState.preference, CameraSourceKind.webcam);
    },
  );

  test(
    'USB attachment refreshes availability without overriding manual choice',
    () async {
      final usb = _FakeWebcam();
      final store = _MemoryPreferenceStore()..saved = CameraSourceKind.phone;
      final gateway = SelectableCameraGateway(_FakeCamera(), usb, store);
      addTearDown(gateway.dispose);
      await gateway.refreshSources();
      expect(gateway.sourceState.webcamAvailable, isFalse);

      final changed = gateway.sourceChanges.firstWhere(
        (state) => state.webcamAvailable,
      );
      usb.devices = [webcam];
      usb.events.add(Object());
      await changed.timeout(const Duration(seconds: 2));

      expect(gateway.sourceState.webcamAvailable, isTrue);
      expect(gateway.sourceState.selected, CameraSourceKind.phone);
    },
  );

  test('USB discovery error keeps the internal camera available', () async {
    final phone = _FakeCamera();
    final usb = _FakeWebcam()..discoveryFails = true;
    final gateway = SelectableCameraGateway(
      phone,
      usb,
      _MemoryPreferenceStore(),
    );
    addTearDown(gateway.dispose);

    await gateway.initialize(const CameraConfiguration());
    expect(gateway.sourceState.active, CameraSourceKind.phone);
    expect(phone.configuration, isNotNull);
  });
}
