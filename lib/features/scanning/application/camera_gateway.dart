import 'package:eyes_mobile/features/scanning/application/camera_configuration.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_frame.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_permission_state.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_telemetry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef CameraFrameHandler = Future<void> Function(CameraFrame frame);
typedef CameraTelemetryHandler = void Function(CameraTelemetry telemetry);
typedef CameraErrorHandler = void Function(CameraGatewayException failure);

enum CameraGatewayFailureReason {
  permissionDenied,
  permissionPermanentlyDenied,
  permissionRestricted,
  busy,
  noCamera,
  initialization,
  stream,
}

final class CameraGatewayException implements Exception {
  const CameraGatewayException(this.reason, {this.code});

  final CameraGatewayFailureReason reason;
  final String? code;
}

abstract interface class CameraGateway {
  double? get previewAspectRatio;

  bool get isPreviewReady;

  Future<CameraPermissionState> checkPermission();

  Future<CameraPermissionState> requestPermission();

  Future<bool> openSettings();

  Future<void> initialize(CameraConfiguration configuration);

  Future<void> startStream({
    required CameraFrameHandler onFrame,
    required CameraTelemetryHandler onTelemetry,
    required CameraErrorHandler onError,
  });

  Future<void> release();
}

final Provider<CameraGateway> cameraGatewayProvider = Provider<CameraGateway>(
  (Ref ref) => throw StateError(
    'CameraGateway must be overridden in the application composition root.',
  ),
);

final Provider<CameraConfiguration> cameraConfigurationProvider =
    Provider<CameraConfiguration>((Ref ref) => const CameraConfiguration());

final Provider<CameraFrameHandler> cameraFrameHandlerProvider =
    Provider<CameraFrameHandler>((Ref ref) {
      return (CameraFrame frame) async {
        // The composition root replaces this safe default with the complete
        // camera → local inference → proximity pipeline.
      };
    });
