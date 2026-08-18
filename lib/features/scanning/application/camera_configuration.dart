enum CameraResolution { low, medium, high }

final class CameraConfiguration {
  const CameraConfiguration({
    this.resolution = CameraResolution.medium,
    this.targetFramesPerSecond = 12,
    this.initializationTimeout = const Duration(seconds: 12),
  }) : assert(targetFramesPerSecond > 0);

  final CameraResolution resolution;
  final int targetFramesPerSecond;
  final Duration initializationTimeout;
}
