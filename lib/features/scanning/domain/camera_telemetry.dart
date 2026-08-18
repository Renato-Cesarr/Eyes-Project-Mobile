final class CameraTelemetry {
  const CameraTelemetry({
    this.receivedFrames = 0,
    this.processedFrames = 0,
    this.droppedFrames = 0,
    this.framesPerSecond = 0,
    this.lastProcessingTime = Duration.zero,
  });

  final int receivedFrames;
  final int processedFrames;
  final int droppedFrames;
  final double framesPerSecond;
  final Duration lastProcessingTime;
}
