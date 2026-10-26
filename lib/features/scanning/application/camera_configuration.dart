import 'package:eyes_mobile/features/scanning/application/camera_source.dart';

enum CameraResolution { low, medium, high }

final class CameraConfiguration {
  const CameraConfiguration({
    this.resolution = CameraResolution.medium,
    this.targetFramesPerSecond = 12,
    // Includes the first Android USB access dialog and UVC mode negotiation.
    this.initializationTimeout = const Duration(seconds: 30),
    this.source = CameraSourceKind.phone,
    this.webcamDeviceId,
  }) : assert(targetFramesPerSecond > 0);

  final CameraResolution resolution;
  final int targetFramesPerSecond;
  final Duration initializationTimeout;
  final CameraSourceKind source;
  final int? webcamDeviceId;

  CameraConfiguration withSource(
    CameraSourceKind kind, {
    int? webcamDeviceId,
  }) => CameraConfiguration(
    resolution: resolution,
    targetFramesPerSecond: targetFramesPerSecond,
    initializationTimeout: initializationTimeout,
    source: kind,
    webcamDeviceId: webcamDeviceId,
  );
}
