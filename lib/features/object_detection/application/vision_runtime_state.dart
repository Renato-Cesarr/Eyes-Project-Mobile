import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';

enum VisionRuntimeStatus { ready, paused }

final class VisionRuntimeState {
  const VisionRuntimeState({
    required this.status,
    this.lastDetection,
    this.processedFrames = 0,
  });

  const VisionRuntimeState.ready()
    : status = VisionRuntimeStatus.ready,
      lastDetection = null,
      processedFrames = 0;

  const VisionRuntimeState.paused()
    : status = VisionRuntimeStatus.paused,
      lastDetection = null,
      processedFrames = 0;

  final VisionRuntimeStatus status;
  final DetectionBatch? lastDetection;
  final int processedFrames;

  VisionRuntimeState copyWith({
    VisionRuntimeStatus? status,
    DetectionBatch? lastDetection,
    int? processedFrames,
  }) {
    return VisionRuntimeState(
      status: status ?? this.status,
      lastDetection: lastDetection ?? this.lastDetection,
      processedFrames: processedFrames ?? this.processedFrames,
    );
  }
}
