import 'package:eyes_mobile/features/object_detection/application/vision_frame.dart';
import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum VisionWorkerPhase { idle, starting, ready, disposing, failed }

enum VisionWorkerFailureReason {
  notReady,
  busy,
  startupTimeout,
  requestTimeout,
  disposeTimeout,
  initialization,
  invalidFrame,
  inference,
  isolateCrashed,
}

final class VisionWorkerException implements Exception {
  const VisionWorkerException(this.reason, this.message, {this.technicalCode});

  final VisionWorkerFailureReason reason;
  final String message;
  final String? technicalCode;

  @override
  String toString() =>
      'VisionWorkerException(${reason.name}, code: $technicalCode): $message';
}

final class VisionWorkerSnapshot {
  const VisionWorkerSnapshot({required this.phase, this.failure});

  const VisionWorkerSnapshot.idle()
    : phase = VisionWorkerPhase.idle,
      failure = null;

  final VisionWorkerPhase phase;
  final VisionWorkerException? failure;
}

abstract interface class VisionWorker {
  VisionWorkerSnapshot get snapshot;

  Stream<VisionWorkerSnapshot> get snapshots;

  Future<void> start();

  Future<DetectionBatch> detect(VisionFrame frame);

  /// Releases the isolate and its interpreter. A new [start] creates a fresh
  /// runtime, which supports app background/foreground transitions.
  Future<void> dispose();
}

final Provider<VisionWorker> visionWorkerProvider = Provider<VisionWorker>(
  (Ref ref) => throw StateError(
    'VisionWorker must be overridden in the application composition root.',
  ),
);
