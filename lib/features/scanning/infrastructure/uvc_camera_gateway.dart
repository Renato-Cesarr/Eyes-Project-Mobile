import 'dart:async';

import 'package:eyes_mobile/features/scanning/application/camera_configuration.dart';
import 'package:eyes_mobile/features/scanning/application/camera_gateway.dart';
import 'package:eyes_mobile/features/scanning/application/camera_source.dart';
import 'package:eyes_mobile/features/scanning/application/latest_frame_processor.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_frame.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_permission_state.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_telemetry.dart';
import 'package:eyes_mobile/features/scanning/infrastructure/mobile_camera_gateway.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ffi_uvc/flutter_ffi_uvc.dart';
import 'package:permission_handler/permission_handler.dart';

abstract interface class WebcamCameraGateway implements CameraGateway {
  Future<List<WebcamDevice>> discover();

  Stream<Object?> get deviceEvents;

  int? get previewTextureId;

  Future<void> dispose();
}

/// Direct UVC capture also works on Android builds without an external Camera2 HAL.
/// Native texture paints the preview; a bounded poll copies only fresh RGBA frames
/// into the existing offline worker pipeline. No recording APIs are used.
final class UvcCameraGateway implements WebcamCameraGateway {
  UvcCameraGateway(
    this._camera, [
    this._permissionDriver = const PermissionHandlerCameraDriver(),
    this._clock = DateTime.now,
  ]);

  final UvcCamera _camera;
  final CameraPermissionDriver _permissionDriver;
  final FrameClock _clock;
  int? _textureId;
  double? _aspectRatio;
  int? _openedDeviceId;
  Timer? _frameTimer;
  LatestFrameProcessor<CameraFrame>? _processor;
  StreamSubscription<UvcDeviceEvent>? _deviceSubscription;
  StreamSubscription<UvcStreamError>? _errorSubscription;
  CameraErrorHandler? _onError;
  CameraTelemetryHandler? _onTelemetry;
  DateTime? _lastFreshFrame;
  DateTime? _telemetryStarted;
  DateTime? _lastTelemetry;
  int _lastSequence = -1;
  bool _failureReported = false;
  bool _released = true;
  int _targetFramesPerSecond = 12;

  @override
  Stream<Object?> get deviceEvents => _camera.deviceEvents;

  @override
  int? get previewTextureId => _textureId;

  @override
  double? get previewAspectRatio => _aspectRatio;

  @override
  bool get isPreviewReady => _textureId != null && _camera.isPreviewing;

  @override
  Future<List<WebcamDevice>> discover() async {
    final devices = await _camera.listUsbDevices();
    devices.sort((a, b) => a.deviceId.compareTo(b.deviceId));
    return devices
        .map(
          (device) => WebcamDevice(
            id: device.deviceId,
            name: device.productName.isEmpty
                ? 'Webcam USB'
                : device.productName,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<CameraPermissionState> checkPermission() async =>
      _mapPermission(await _permissionDriver.check());

  @override
  Future<CameraPermissionState> requestPermission() async =>
      _mapPermission(await _permissionDriver.request());

  @override
  Future<bool> openSettings() => _permissionDriver.openSettings();

  @override
  Future<void> initialize(CameraConfiguration configuration) async {
    await release();
    final deviceId = configuration.webcamDeviceId;
    if (deviceId == null) {
      throw const CameraGatewayException(
        CameraGatewayFailureReason.noCamera,
        code: 'webcam-not-connected',
      );
    }
    _released = false;
    _targetFramesPerSecond = configuration.targetFramesPerSecond;
    try {
      await _camera.openUsbDevice(deviceId);
      _openedDeviceId = deviceId;
      final modes = _preferredModes(_camera.supportedModes());
      final result = await _camera.startPreviewAuto(
        candidates: modes.isEmpty ? null : modes,
        maxCandidates: 4,
        perModeTimeout: const Duration(seconds: 2),
      );
      if (!result.success || result.mode == null) {
        throw const CameraGatewayException(
          CameraGatewayFailureReason.initialization,
          code: 'webcam-no-valid-video-mode',
        );
      }
      final mode = result.mode!;
      _aspectRatio = mode.width / mode.height;
      final texture = await _camera.createPreviewTexture();
      _textureId = texture;
      await _camera.attachPreviewTexture(
        texture,
        width: mode.width,
        height: mode.height,
      );
    } on CameraGatewayException {
      await release();
      rethrow;
    } on UvcException catch (error) {
      await release();
      throw _mapUvcError(error.code);
    } on PlatformException catch (error) {
      await release();
      throw CameraGatewayException(switch (error.code) {
        'permission_denied' => CameraGatewayFailureReason.permissionDenied,
        'not_found' => CameraGatewayFailureReason.noCamera,
        'superseded' => CameraGatewayFailureReason.busy,
        _ => CameraGatewayFailureReason.initialization,
      }, code: 'webcam-usb-${error.code}');
    } on Object {
      await release();
      throw const CameraGatewayException(
        CameraGatewayFailureReason.initialization,
        code: 'webcam-startup-failed',
      );
    }
  }

  static List<UvcCameraMode> _preferredModes(List<UvcCameraMode> modes) {
    final candidates = modes.where(
      (mode) =>
          mode.width >= 320 &&
          mode.height >= 240 &&
          mode.width <= 1280 &&
          mode.height <= 720 &&
          mode.fps >= 10,
    );
    final sorted = candidates.toList()
      ..sort((a, b) {
        final aMjpeg = a.formatName.toUpperCase().contains('MJPEG') ? 0 : 1;
        final bMjpeg = b.formatName.toUpperCase().contains('MJPEG') ? 0 : 1;
        if (aMjpeg != bMjpeg) return aMjpeg.compareTo(bMjpeg);
        final aDistance = ((a.width * a.height) - 640 * 480).abs();
        final bDistance = ((b.width * b.height) - 640 * 480).abs();
        return aDistance.compareTo(bDistance);
      });
    return sorted.take(4).toList(growable: false);
  }

  @override
  Future<void> startStream({
    required CameraFrameHandler onFrame,
    required CameraTelemetryHandler onTelemetry,
    required CameraErrorHandler onError,
  }) async {
    if (!isPreviewReady || _openedDeviceId == null) {
      throw const CameraGatewayException(
        CameraGatewayFailureReason.initialization,
        code: 'webcam-not-ready',
      );
    }
    _onError = onError;
    _onTelemetry = onTelemetry;
    _failureReported = false;
    _lastSequence = -1;
    _telemetryStarted = _clock();
    _lastFreshFrame = _telemetryStarted;
    _processor = LatestFrameProcessor<CameraFrame>(
      minimumInterval: Duration.zero,
      clock: _clock,
      onFrame: (frame) async {
        try {
          await onFrame(frame);
        } on Object {
          _reportFailure(
            const CameraGatewayException(
              CameraGatewayFailureReason.stream,
              code: 'webcam-frame-consumer-failed',
            ),
          );
        } finally {
          _publishTelemetry();
        }
      },
    );
    _deviceSubscription = _camera.deviceEvents.listen((event) {
      if (event.type == UvcDeviceEventType.detached &&
          event.device.deviceId == _openedDeviceId) {
        _reportFailure(
          const CameraGatewayException(
            CameraGatewayFailureReason.stream,
            code: 'webcam-disconnected',
          ),
        );
      }
    });
    _errorSubscription = _camera.streamErrors.listen((_) {
      // An isolated decode error can be transient; the stall check detects
      // sustained loss of usable frames without exposing native details.
    });
    final period = Duration(
      microseconds: Duration.microsecondsPerSecond ~/ _targetFramesPerSecond,
    );
    _frameTimer = Timer.periodic(period, (_) => _pollFrame());
  }

  void _pollFrame() {
    if (_released || _failureReported) return;
    try {
      final frame = _camera.copyLatestFrame();
      if (frame != null && frame.sequence != _lastSequence) {
        if (frame.width <= 0 ||
            frame.height <= 0 ||
            frame.rgbaBytes.length != frame.width * frame.height * 4) {
          _reportFailure(
            const CameraGatewayException(
              CameraGatewayFailureReason.stream,
              code: 'webcam-invalid-frame',
            ),
          );
          return;
        }
        _lastSequence = frame.sequence;
        _lastFreshFrame = _clock();
        _processor?.add(
          CameraFrame(
            width: frame.width,
            height: frame.height,
            format: CameraPixelFormat.rgba8888,
            planes: <CameraFramePlane>[
              CameraFramePlane(
                bytes: frame.rgbaBytes,
                bytesPerRow: frame.width * 4,
                bytesPerPixel: 4,
              ),
            ],
            rotation: CameraFrameRotation.degrees0,
            capturedAt: _clock(),
          ),
        );
      }
      final freshAt = _lastFreshFrame;
      if (freshAt != null &&
          _clock().difference(freshAt) > const Duration(seconds: 3)) {
        _reportFailure(
          const CameraGatewayException(
            CameraGatewayFailureReason.stream,
            code: 'webcam-frame-stalled',
          ),
        );
      }
      _publishTelemetry();
    } on Object {
      _reportFailure(
        const CameraGatewayException(
          CameraGatewayFailureReason.stream,
          code: 'webcam-frame-read-failed',
        ),
      );
    }
  }

  void _publishTelemetry() {
    final callback = _onTelemetry;
    final start = _telemetryStarted;
    if (callback == null || start == null) return;
    final now = _clock();
    if (_lastTelemetry != null &&
        now.difference(_lastTelemetry!) < const Duration(milliseconds: 500)) {
      return;
    }
    final snapshot = _processor?.snapshot;
    final seconds =
        now.difference(start).inMicroseconds / Duration.microsecondsPerSecond;
    callback(
      CameraTelemetry(
        receivedFrames: snapshot?.received ?? 0,
        processedFrames: snapshot?.processed ?? 0,
        droppedFrames: snapshot?.dropped ?? 0,
        framesPerSecond: seconds <= 0
            ? 0
            : (snapshot?.processed ?? 0) / seconds,
        lastProcessingTime: snapshot?.lastProcessingTime ?? Duration.zero,
      ),
    );
    _lastTelemetry = now;
  }

  void _reportFailure(CameraGatewayException failure) {
    if (_failureReported || _released) return;
    _failureReported = true;
    _frameTimer?.cancel();
    _onError?.call(failure);
  }

  @override
  Future<void> release() async {
    _released = true;
    _frameTimer?.cancel();
    _frameTimer = null;
    await _deviceSubscription?.cancel();
    _deviceSubscription = null;
    await _errorSubscription?.cancel();
    _errorSubscription = null;
    final processor = _processor;
    _processor = null;
    if (processor != null) await processor.close();
    try {
      await _camera.stopPreview();
    } on Object {
      // Continue cleanup after transport loss.
    }
    final texture = _textureId;
    _textureId = null;
    if (texture != null) {
      try {
        await _camera.disposePreviewTexture(texture);
      } on Object {
        // Continue closing the USB device.
      }
    }
    try {
      await _camera.closeUsbDevice();
    } on Object {
      // A detached device is already gone.
    }
    _openedDeviceId = null;
    _aspectRatio = null;
    _onTelemetry = null;
    _onError = null;
  }

  @override
  Future<void> dispose() async {
    await release();
    await _camera.dispose();
  }

  static CameraPermissionState _mapPermission(PermissionStatus status) =>
      switch (status) {
        PermissionStatus.granted ||
        PermissionStatus.provisional => CameraPermissionState.granted,
        PermissionStatus.permanentlyDenied =>
          CameraPermissionState.permanentlyDenied,
        PermissionStatus.restricted ||
        PermissionStatus.limited => CameraPermissionState.restricted,
        PermissionStatus.denied => CameraPermissionState.denied,
      };

  static CameraGatewayException _mapUvcError(UvcErrorCode code) =>
      CameraGatewayException(switch (code) {
        UvcErrorCode.access => CameraGatewayFailureReason.permissionDenied,
        UvcErrorCode.busy => CameraGatewayFailureReason.busy,
        UvcErrorCode.noDevice => CameraGatewayFailureReason.noCamera,
        _ => CameraGatewayFailureReason.initialization,
      }, code: 'webcam-${code.name}');
}
