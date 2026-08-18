import 'dart:async';

import 'package:camera/camera.dart';
import 'package:eyes_mobile/features/scanning/application/camera_configuration.dart';
import 'package:eyes_mobile/features/scanning/application/camera_gateway.dart';
import 'package:eyes_mobile/features/scanning/application/latest_frame_processor.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_frame.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_permission_state.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_telemetry.dart';
import 'package:permission_handler/permission_handler.dart';

abstract interface class CameraPermissionDriver {
  Future<PermissionStatus> check();

  Future<PermissionStatus> request();

  Future<bool> openSettings();
}

final class PermissionHandlerCameraDriver implements CameraPermissionDriver {
  const PermissionHandlerCameraDriver();

  @override
  Future<PermissionStatus> check() => Permission.camera.status;

  @override
  Future<bool> openSettings() => openAppSettings();

  @override
  Future<PermissionStatus> request() => Permission.camera.request();
}

abstract interface class CameraDeviceController {
  CameraController? get previewController;

  bool get isInitialized;

  bool get isStreamingImages;

  bool get hasError;

  double get aspectRatio;

  int? get configuredFramesPerSecond;

  void addListener(void Function() listener);

  void removeListener(void Function() listener);

  Future<void> initialize();

  Future<void> startImageStream(void Function(CameraImage image) onImage);

  Future<void> stopImageStream();

  Future<void> dispose();
}

abstract interface class CameraPluginDriver {
  Future<List<CameraDescription>> available();

  CameraDeviceController createController({
    required CameraDescription description,
    required ResolutionPreset resolution,
    required int framesPerSecond,
  });
}

final class FlutterCameraPluginDriver implements CameraPluginDriver {
  const FlutterCameraPluginDriver();

  @override
  Future<List<CameraDescription>> available() => availableCameras();

  @override
  CameraDeviceController createController({
    required CameraDescription description,
    required ResolutionPreset resolution,
    required int framesPerSecond,
  }) {
    return FlutterCameraDeviceController(
      CameraController(
        description,
        resolution,
        enableAudio: false,
        fps: framesPerSecond,
        imageFormatGroup: ImageFormatGroup.nv21,
      ),
    );
  }
}

final class FlutterCameraDeviceController implements CameraDeviceController {
  const FlutterCameraDeviceController(this._controller);

  final CameraController _controller;

  @override
  double get aspectRatio => _controller.value.aspectRatio;

  @override
  int? get configuredFramesPerSecond => _controller.mediaSettings.fps;

  @override
  bool get hasError => _controller.value.hasError;

  @override
  bool get isInitialized => _controller.value.isInitialized;

  @override
  bool get isStreamingImages => _controller.value.isStreamingImages;

  @override
  CameraController get previewController => _controller;

  @override
  void addListener(void Function() listener) =>
      _controller.addListener(listener);

  @override
  Future<void> dispose() => _controller.dispose();

  @override
  Future<void> initialize() => _controller.initialize();

  @override
  void removeListener(void Function() listener) =>
      _controller.removeListener(listener);

  @override
  Future<void> startImageStream(void Function(CameraImage image) onImage) =>
      _controller.startImageStream(onImage);

  @override
  Future<void> stopImageStream() => _controller.stopImageStream();
}

final class MobileCameraGateway implements CameraGateway {
  MobileCameraGateway({
    this.cameraDriver = const FlutterCameraPluginDriver(),
    this.permissionDriver = const PermissionHandlerCameraDriver(),
    this.clock = DateTime.now,
  });

  final CameraPluginDriver cameraDriver;
  final CameraPermissionDriver permissionDriver;
  final FrameClock clock;

  CameraDeviceController? _controller;
  LatestFrameProcessor<CameraImage>? _frameProcessor;
  CameraTelemetryHandler? _onTelemetry;
  CameraErrorHandler? _onError;
  DateTime? _telemetryWindowStartedAt;
  DateTime? _lastTelemetryPublishedAt;
  int _processedAtWindowStart = 0;
  int _receivedFrames = 0;
  int _processedFrames = 0;
  Duration _lastProcessingTime = Duration.zero;
  bool _nativeErrorReported = false;

  CameraController? get previewController =>
      isPreviewReady ? _controller?.previewController : null;

  @override
  double? get previewAspectRatio =>
      isPreviewReady ? _controller?.aspectRatio : null;

  @override
  bool get isPreviewReady => _controller?.isInitialized ?? false;

  @override
  Future<CameraPermissionState> checkPermission() async {
    return _mapPermission(await permissionDriver.check());
  }

  @override
  Future<CameraPermissionState> requestPermission() async {
    return _mapPermission(await permissionDriver.request());
  }

  @override
  Future<bool> openSettings() => permissionDriver.openSettings();

  @override
  Future<void> initialize(CameraConfiguration configuration) async {
    await release();

    try {
      final cameras = await cameraDriver.available();
      if (cameras.isEmpty) {
        throw const CameraGatewayException(
          CameraGatewayFailureReason.noCamera,
          code: 'no-camera',
        );
      }

      final selectedCamera = cameras.firstWhere(
        (CameraDescription camera) =>
            camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = cameraDriver.createController(
        description: selectedCamera,
        resolution: _mapResolution(configuration.resolution),
        framesPerSecond: configuration.targetFramesPerSecond,
      );
      _controller = controller;
      _nativeErrorReported = false;
      controller.addListener(_handleControllerValue);
      await controller.initialize();

      if (!identical(_controller, controller)) {
        await controller.dispose();
        throw const CameraGatewayException(
          CameraGatewayFailureReason.initialization,
          code: 'initialization-cancelled',
        );
      }
    } on CameraGatewayException {
      rethrow;
    } on CameraException catch (error) {
      await _disposeController();
      throw _mapCameraException(error, duringStream: false);
    } on Object {
      await _disposeController();
      throw const CameraGatewayException(
        CameraGatewayFailureReason.initialization,
        code: 'initialization-failed',
      );
    }
  }

  @override
  Future<void> startStream({
    required CameraFrameHandler onFrame,
    required CameraTelemetryHandler onTelemetry,
    required CameraErrorHandler onError,
  }) async {
    final controller = _controller;
    if (controller == null || !controller.isInitialized) {
      throw const CameraGatewayException(
        CameraGatewayFailureReason.initialization,
        code: 'camera-not-initialized',
      );
    }

    _resetTelemetry();
    _onTelemetry = onTelemetry;
    _onError = onError;
    final configuredFps = controller.configuredFramesPerSecond ?? 12;
    final minimumInterval = Duration(
      microseconds: Duration.microsecondsPerSecond ~/ configuredFps,
    );
    final processor = LatestFrameProcessor<CameraImage>(
      minimumInterval: minimumInterval,
      clock: clock,
      onFrame: (CameraImage image) async {
        final startedAt = clock();
        try {
          await onFrame(_mapFrame(image, capturedAt: clock()));
        } on Object {
          _reportError(
            const CameraGatewayException(
              CameraGatewayFailureReason.stream,
              code: 'frame-consumer-failed',
            ),
          );
        } finally {
          _processedFrames++;
          _lastProcessingTime = clock().difference(startedAt);
          _publishTelemetry(force: _processedFrames == 1);
        }
      },
    );
    _frameProcessor = processor;

    try {
      await controller.startImageStream((CameraImage image) {
        _receivedFrames++;
        processor.add(image);
        _publishTelemetry();
      });
      _publishTelemetry(force: true);
    } on CameraException catch (error) {
      await processor.close();
      _frameProcessor = null;
      throw _mapCameraException(error, duringStream: true);
    } on Object {
      await processor.close();
      _frameProcessor = null;
      throw const CameraGatewayException(
        CameraGatewayFailureReason.stream,
        code: 'stream-start-failed',
      );
    }
  }

  @override
  Future<void> release() async {
    final controller = _controller;
    if (controller != null && controller.isStreamingImages) {
      try {
        await controller.stopImageStream();
      } on Object {
        // Disposal below remains the source of truth for releasing hardware.
      }
    }

    final processor = _frameProcessor;
    _frameProcessor = null;
    if (processor != null) {
      await processor.close();
    }
    await _disposeController();
    _onTelemetry = null;
    _onError = null;
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) {
      return;
    }
    controller.removeListener(_handleControllerValue);
    try {
      await controller.dispose();
    } on Object {
      // dispose is best-effort and release remains idempotent.
    }
  }

  void _handleControllerValue() {
    final controller = _controller;
    if (controller == null || !controller.hasError || _nativeErrorReported) {
      return;
    }
    _nativeErrorReported = true;
    _reportError(
      const CameraGatewayException(
        CameraGatewayFailureReason.stream,
        code: 'native-camera-error',
      ),
    );
  }

  void _reportError(CameraGatewayException failure) {
    _onError?.call(failure);
  }

  void _resetTelemetry() {
    final now = clock();
    _telemetryWindowStartedAt = now;
    _lastTelemetryPublishedAt = null;
    _processedAtWindowStart = 0;
    _receivedFrames = 0;
    _processedFrames = 0;
    _lastProcessingTime = Duration.zero;
  }

  void _publishTelemetry({bool force = false}) {
    final callback = _onTelemetry;
    final windowStartedAt = _telemetryWindowStartedAt;
    if (callback == null || windowStartedAt == null) {
      return;
    }
    final now = clock();
    final lastPublishedAt = _lastTelemetryPublishedAt;
    if (!force &&
        lastPublishedAt != null &&
        now.difference(lastPublishedAt) < const Duration(milliseconds: 500)) {
      return;
    }

    final elapsed = now.difference(windowStartedAt);
    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final fps = seconds <= 0
        ? 0.0
        : (_processedFrames - _processedAtWindowStart) / seconds;
    final processorSnapshot = _frameProcessor?.snapshot;
    callback(
      CameraTelemetry(
        receivedFrames: _receivedFrames,
        processedFrames: _processedFrames,
        droppedFrames: processorSnapshot?.dropped ?? 0,
        framesPerSecond: fps,
        lastProcessingTime: _lastProcessingTime,
      ),
    );
    _lastTelemetryPublishedAt = now;

    if (elapsed >= const Duration(seconds: 3)) {
      _telemetryWindowStartedAt = now;
      _processedAtWindowStart = _processedFrames;
    }
  }

  static CameraFrame _mapFrame(
    CameraImage image, {
    required DateTime capturedAt,
  }) {
    return CameraFrame(
      width: image.width,
      height: image.height,
      format: switch (image.format.group) {
        ImageFormatGroup.nv21 => CameraPixelFormat.nv21,
        ImageFormatGroup.yuv420 => CameraPixelFormat.yuv420,
        ImageFormatGroup.bgra8888 => CameraPixelFormat.bgra8888,
        _ => CameraPixelFormat.unknown,
      },
      planes: image.planes
          .map(
            (Plane plane) => CameraFramePlane(
              bytes: plane.bytes,
              bytesPerRow: plane.bytesPerRow,
              bytesPerPixel: plane.bytesPerPixel,
            ),
          )
          .toList(growable: false),
      capturedAt: capturedAt,
    );
  }

  static CameraPermissionState _mapPermission(PermissionStatus status) {
    return switch (status) {
      PermissionStatus.granted ||
      PermissionStatus.provisional => CameraPermissionState.granted,
      PermissionStatus.permanentlyDenied =>
        CameraPermissionState.permanentlyDenied,
      PermissionStatus.restricted ||
      PermissionStatus.limited => CameraPermissionState.restricted,
      PermissionStatus.denied => CameraPermissionState.denied,
    };
  }

  static ResolutionPreset _mapResolution(CameraResolution resolution) {
    return switch (resolution) {
      CameraResolution.low => ResolutionPreset.low,
      CameraResolution.medium => ResolutionPreset.medium,
      CameraResolution.high => ResolutionPreset.high,
    };
  }

  static CameraGatewayException _mapCameraException(
    CameraException error, {
    required bool duringStream,
  }) {
    final normalized = '${error.code} ${error.description ?? ''}'.toLowerCase();
    if (normalized.contains('withoutprompt') ||
        normalized.contains('permanently')) {
      return CameraGatewayException(
        CameraGatewayFailureReason.permissionPermanentlyDenied,
        code: error.code,
      );
    }
    if (normalized.contains('denied')) {
      return CameraGatewayException(
        CameraGatewayFailureReason.permissionDenied,
        code: error.code,
      );
    }
    if (normalized.contains('restricted')) {
      return CameraGatewayException(
        CameraGatewayFailureReason.permissionRestricted,
        code: error.code,
      );
    }
    if (normalized.contains('busy') ||
        normalized.contains('in use') ||
        normalized.contains('access')) {
      return CameraGatewayException(
        CameraGatewayFailureReason.busy,
        code: error.code,
      );
    }
    return CameraGatewayException(
      duringStream
          ? CameraGatewayFailureReason.stream
          : CameraGatewayFailureReason.initialization,
      code: error.code,
    );
  }
}
