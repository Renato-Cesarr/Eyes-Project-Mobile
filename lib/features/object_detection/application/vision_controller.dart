import 'dart:async';

import 'package:eyes_mobile/core/error/app_error_reporter.dart';
import 'package:eyes_mobile/features/object_detection/application/vision_frame.dart';
import 'package:eyes_mobile/features/object_detection/application/vision_runtime_state.dart';
import 'package:eyes_mobile/features/object_detection/application/vision_worker.dart';
import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class VisionController extends AsyncNotifier<VisionRuntimeState> {
  StreamSubscription<VisionWorkerSnapshot>? _snapshotSubscription;
  bool _isDisposed = false;
  bool _resumeAfterLifecycle = false;

  @override
  Future<VisionRuntimeState> build() async {
    _isDisposed = false;
    final worker = ref.read(visionWorkerProvider);
    _snapshotSubscription = worker.snapshots.listen(_handleWorkerSnapshot);
    ref.onDispose(() {
      _isDisposed = true;
      unawaited(_snapshotSubscription?.cancel());
      _snapshotSubscription = null;
      unawaited(worker.dispose());
    });

    try {
      await worker.start();
      return const VisionRuntimeState.ready();
    } on VisionWorkerException catch (error) {
      if (_resumeAfterLifecycle &&
          error.technicalCode == 'vision-start-cancelled') {
        return const VisionRuntimeState.paused();
      }
      rethrow;
    }
  }

  Future<DetectionBatch> process(VisionFrame frame) async {
    final current = state.asData?.value;
    if (current?.status != VisionRuntimeStatus.ready) {
      throw const VisionWorkerException(
        VisionWorkerFailureReason.notReady,
        'A visão computacional ainda não está pronta.',
        technicalCode: 'vision-runtime-not-ready',
      );
    }

    try {
      final result = await ref.read(visionWorkerProvider).detect(frame);
      if (!_isDisposed) {
        state = AsyncData<VisionRuntimeState>(
          current!.copyWith(
            lastDetection: result,
            processedFrames: current.processedFrames + 1,
          ),
        );
      }
      return result;
    } on Object catch (error, stackTrace) {
      _publishFailure(error, stackTrace, source: 'vision-frame-processing');
      rethrow;
    }
  }

  Future<void> handleBackground() async {
    final current = state.asData?.value;
    final worker = ref.read(visionWorkerProvider);
    _resumeAfterLifecycle =
        current?.status == VisionRuntimeStatus.ready ||
        worker.snapshot.phase == VisionWorkerPhase.starting ||
        worker.snapshot.phase == VisionWorkerPhase.ready;
    if (!_resumeAfterLifecycle) {
      return;
    }

    try {
      await worker.dispose();
      if (!_isDisposed) {
        state = AsyncData<VisionRuntimeState>(
          current?.copyWith(status: VisionRuntimeStatus.paused) ??
              const VisionRuntimeState.paused(),
        );
      }
    } on Object catch (error, stackTrace) {
      _publishFailure(error, stackTrace, source: 'vision-background-dispose');
    }
  }

  Future<void> handleForeground() async {
    if (!_resumeAfterLifecycle || _isDisposed) {
      return;
    }
    _resumeAfterLifecycle = false;
    state = const AsyncData<VisionRuntimeState>(
      VisionRuntimeState.recovering(),
    );
    try {
      await ref.read(visionWorkerProvider).start();
      if (!_isDisposed) {
        state = const AsyncData<VisionRuntimeState>(VisionRuntimeState.ready());
      }
    } on Object catch (error, stackTrace) {
      _publishFailure(error, stackTrace, source: 'vision-foreground-start');
    }
  }

  Future<void> retry() async {
    if (_isDisposed) {
      return;
    }
    state = const AsyncData<VisionRuntimeState>(
      VisionRuntimeState.recovering(),
    );
    try {
      await ref.read(visionWorkerProvider).dispose();
      await ref.read(visionWorkerProvider).start();
      if (!_isDisposed) {
        state = const AsyncData<VisionRuntimeState>(VisionRuntimeState.ready());
      }
    } on Object catch (error, stackTrace) {
      _publishFailure(error, stackTrace, source: 'vision-retry');
    }
  }

  Future<void> start() async {
    if (_isDisposed ||
        state.asData?.value.status == VisionRuntimeStatus.ready) {
      return;
    }
    _resumeAfterLifecycle = false;
    state = const AsyncData<VisionRuntimeState>(
      VisionRuntimeState.recovering(),
    );
    try {
      await ref.read(visionWorkerProvider).start();
      if (!_isDisposed) {
        state = const AsyncData<VisionRuntimeState>(VisionRuntimeState.ready());
      }
    } on Object catch (error, stackTrace) {
      _publishFailure(error, stackTrace, source: 'vision-manual-start');
    }
  }

  Future<void> stop() async {
    _resumeAfterLifecycle = false;
    try {
      await ref.read(visionWorkerProvider).dispose();
      if (!_isDisposed) {
        state = const AsyncData<VisionRuntimeState>(
          VisionRuntimeState.paused(),
        );
      }
    } on Object catch (error, stackTrace) {
      _publishFailure(error, stackTrace, source: 'vision-manual-stop');
    }
  }

  void _handleWorkerSnapshot(VisionWorkerSnapshot snapshot) {
    final failure = snapshot.failure;
    if (_isDisposed ||
        snapshot.phase != VisionWorkerPhase.failed ||
        failure == null) {
      return;
    }
    _publishFailure(failure, StackTrace.current, source: 'vision-isolate');
  }

  void _publishFailure(
    Object error,
    StackTrace stackTrace, {
    required String source,
  }) {
    if (_isDisposed) {
      return;
    }
    ref
        .read(appErrorReporterProvider)
        .capture(
          error,
          stackTrace,
          source: source,
          diagnosticCode: error is VisionWorkerException
              ? error.technicalCode
              : null,
        );
    state = AsyncError<VisionRuntimeState>(error, stackTrace);
  }
}

final AsyncNotifierProvider<VisionController, VisionRuntimeState>
visionControllerProvider =
    AsyncNotifierProvider<VisionController, VisionRuntimeState>(
      VisionController.new,
    );
