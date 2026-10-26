import 'dart:async';
import 'dart:collection';

import 'package:eyes_mobile/features/scanning/application/camera_configuration.dart';
import 'package:eyes_mobile/features/scanning/application/camera_gateway.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_frame.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_permission_state.dart';
import 'package:eyes_mobile/features/scanning/infrastructure/mobile_camera_gateway.dart';
import 'package:eyes_mobile/features/scanning/infrastructure/uvc_camera_gateway.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ffi_uvc/flutter_ffi_uvc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

const _device = UvcUsbDevice(
  deviceId: 42,
  deviceName: 'usb/42',
  vendorId: 1,
  productId: 2,
  productName: 'Webcam de teste',
  manufacturerName: 'Fabricante',
  serialNumber: '',
  hasPermission: true,
);

const _mode = UvcCameraMode(
  frameFormat: 1,
  formatName: 'MJPEG',
  width: 640,
  height: 480,
  fps: 30,
);

final class _PermissionDriver implements CameraPermissionDriver {
  PermissionStatus status = PermissionStatus.granted;

  @override
  Future<PermissionStatus> check() async => status;

  @override
  Future<PermissionStatus> request() async => status;

  @override
  Future<bool> openSettings() async => true;
}

final class _FakeUvcCamera implements UvcCamera {
  final events = StreamController<UvcDeviceEvent>.broadcast();
  final frames = ListQueue<UvcPreviewFrame>();
  bool isOpen = false;
  bool previewing = false;
  bool disposed = false;
  bool startSuccess = true;
  Object? openFailure;
  int? attachedTexture;
  int? disposedTexture;
  int closes = 0;
  int stops = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<UvcUsbDevice>> listUsbDevices() async => [_device];

  @override
  Stream<UvcDeviceEvent> get deviceEvents => events.stream;

  @override
  Stream<UvcStreamError> get streamErrors => const Stream.empty();

  @override
  bool get isPreviewing => previewing;

  @override
  Future<void> openUsbDevice(int deviceId) async {
    if (openFailure case final failure?) throw failure;
    expect(deviceId, 42);
    isOpen = true;
  }

  @override
  List<UvcCameraMode> supportedModes() => [_mode];

  @override
  Future<UvcAutoPreviewResult> startPreviewAuto({
    List<UvcCameraMode>? candidates,
    UvcAutoPreviewPreference preference = UvcAutoPreviewPreference.reliability,
    UvcPreviewPolicy policy = UvcPreviewPolicy.stableFrames,
    int consecutiveValidFrames = 3,
    Duration perModeTimeout = const Duration(seconds: 2),
    int maxCandidates = 8,
  }) async {
    expect(candidates, contains(_mode));
    previewing = startSuccess;
    return UvcAutoPreviewResult(
      attempts: [
        UvcPreviewStartResult(
          mode: _mode,
          success: startSuccess,
          validFrameCount: startSuccess ? 3 : 0,
          consecutiveValidFrames: startSuccess ? 3 : 0,
          errorCount: 0,
          elapsed: const Duration(milliseconds: 30),
        ),
      ],
    );
  }

  @override
  Future<int> createPreviewTexture() async => 13;

  @override
  Future<void> attachPreviewTexture(
    int textureId, {
    int? width,
    int? height,
  }) async {
    expect(width, 640);
    expect(height, 480);
    attachedTexture = textureId;
  }

  @override
  UvcPreviewFrame? copyLatestFrame() =>
      frames.isEmpty ? null : frames.removeFirst();

  @override
  Future<void> stopPreview() async {
    stops++;
    previewing = false;
  }

  @override
  Future<void> disposePreviewTexture(int textureId) async {
    disposedTexture = textureId;
  }

  @override
  Future<void> closeUsbDevice() async {
    closes++;
    isOpen = false;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await events.close();
  }
}

void main() {
  test('discovers UVC devices and maps Android permission state', () async {
    final native = _FakeUvcCamera();
    final permissions = _PermissionDriver();
    final gateway = UvcCameraGateway(native, permissions);
    addTearDown(gateway.dispose);

    expect((await gateway.discover()).single.name, 'Webcam de teste');
    expect(await gateway.checkPermission(), CameraPermissionState.granted);
    permissions.status = PermissionStatus.permanentlyDenied;
    expect(
      await gateway.requestPermission(),
      CameraPermissionState.permanentlyDenied,
    );
    expect(await gateway.openSettings(), isTrue);
  });

  test(
    'opens USB preview, emits only fresh RGBA and frees native resources',
    () async {
      final native = _FakeUvcCamera();
      final gateway = UvcCameraGateway(native, _PermissionDriver());
      addTearDown(gateway.dispose);

      await gateway.initialize(const CameraConfiguration(webcamDeviceId: 42));
      expect(gateway.previewTextureId, 13);
      expect(gateway.previewAspectRatio, 4 / 3);
      expect(gateway.isPreviewReady, isTrue);
      expect(native.attachedTexture, 13);

      final seen = Completer<CameraFrame>();
      await gateway.startStream(
        onFrame: (frame) async => seen.complete(frame),
        onTelemetry: (_) {},
        onError: (error) => fail('Unexpected stream failure: ${error.code}'),
      );
      native.frames.add(
        UvcPreviewFrame(
          width: 2,
          height: 2,
          rgbaBytes: Uint8List.fromList(List<int>.filled(16, 255)),
          sequence: 1,
        ),
      );
      final frame = await seen.future.timeout(const Duration(seconds: 2));
      expect(frame.format, CameraPixelFormat.rgba8888);
      expect(frame.planes.single.bytesPerPixel, 4);
      expect(frame.planes.single.bytesPerRow, 8);
      expect(frame.rotation, CameraFrameRotation.degrees0);

      await gateway.release();
      expect(native.isOpen, isFalse);
      expect(native.disposedTexture, 13);
      expect(gateway.isPreviewReady, isFalse);
    },
  );

  test('detaching active USB device reports failure once', () async {
    final native = _FakeUvcCamera();
    final gateway = UvcCameraGateway(native, _PermissionDriver());
    addTearDown(gateway.dispose);
    await gateway.initialize(const CameraConfiguration(webcamDeviceId: 42));
    final failed = Completer<CameraGatewayException>();
    await gateway.startStream(
      onFrame: (_) async {},
      onTelemetry: (_) {},
      onError: (error) => failed.complete(error),
    );

    native.events.add(
      const UvcDeviceEvent(type: UvcDeviceEventType.detached, device: _device),
    );
    final error = await failed.future.timeout(const Duration(seconds: 2));
    expect(error.code, 'webcam-disconnected');
    await gateway.release();
    expect(native.isOpen, isFalse);
  });

  test('invalid RGBA frame stops the stream before inference', () async {
    final native = _FakeUvcCamera();
    final gateway = UvcCameraGateway(native, _PermissionDriver());
    addTearDown(gateway.dispose);
    await gateway.initialize(const CameraConfiguration(webcamDeviceId: 42));
    final failed = Completer<CameraGatewayException>();
    await gateway.startStream(
      onFrame: (_) async => fail('Invalid frame reached inference'),
      onTelemetry: (_) {},
      onError: (error) => failed.complete(error),
    );
    native.frames.add(
      UvcPreviewFrame(
        width: 2,
        height: 2,
        rgbaBytes: Uint8List(3),
        sequence: 1,
      ),
    );

    final error = await failed.future.timeout(const Duration(seconds: 2));
    expect(error.code, 'webcam-invalid-frame');
  });

  test(
    'a stalled USB stream is reported instead of leaving scanning active',
    () async {
      final native = _FakeUvcCamera();
      var now = DateTime.utc(2026);
      final gateway = UvcCameraGateway(native, _PermissionDriver(), () => now);
      addTearDown(gateway.dispose);
      await gateway.initialize(const CameraConfiguration(webcamDeviceId: 42));
      final failed = Completer<CameraGatewayException>();
      await gateway.startStream(
        onFrame: (_) async {},
        onTelemetry: (_) {},
        onError: (error) => failed.complete(error),
      );
      now = now.add(const Duration(seconds: 4));

      final error = await failed.future.timeout(const Duration(seconds: 2));
      expect(error.code, 'webcam-frame-stalled');
    },
  );

  test(
    'maps USB permission denial and invalid video mode to safe failures',
    () async {
      final deniedNative = _FakeUvcCamera()
        ..openFailure = PlatformException(code: 'permission_denied');
      final denied = UvcCameraGateway(deniedNative, _PermissionDriver());
      addTearDown(denied.dispose);
      await expectLater(
        denied.initialize(const CameraConfiguration(webcamDeviceId: 42)),
        throwsA(
          isA<CameraGatewayException>().having(
            (error) => error.reason,
            'reason',
            CameraGatewayFailureReason.permissionDenied,
          ),
        ),
      );
      expect(deniedNative.isOpen, isFalse);

      final noModeNative = _FakeUvcCamera()..startSuccess = false;
      final noMode = UvcCameraGateway(noModeNative, _PermissionDriver());
      addTearDown(noMode.dispose);
      await expectLater(
        noMode.initialize(const CameraConfiguration(webcamDeviceId: 42)),
        throwsA(
          isA<CameraGatewayException>().having(
            (error) => error.code,
            'code',
            'webcam-no-valid-video-mode',
          ),
        ),
      );
      expect(noModeNative.isOpen, isFalse);
    },
  );
}
