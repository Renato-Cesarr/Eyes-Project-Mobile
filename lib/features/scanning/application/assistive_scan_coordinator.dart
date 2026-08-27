import 'package:eyes_mobile/features/assistive_feedback/application/assistive_feedback_controller.dart';
import 'package:eyes_mobile/features/object_detection/application/vision_controller.dart';
import 'package:eyes_mobile/features/object_detection/application/vision_runtime_state.dart';
import 'package:eyes_mobile/features/proximity/application/proximity_controller.dart';
import 'package:eyes_mobile/features/scanning/application/scan_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Coordinates camera and local AI so frames are never produced without a
/// ready consumer and both native resources share the same lifecycle.
final class AssistiveScanCoordinator {
  const AssistiveScanCoordinator(this._ref);

  final Ref _ref;

  Future<void> prepare() async {
    try {
      await _ref.read(assistiveFeedbackControllerProvider.future);
      final runtime = await _ref.read(visionControllerProvider.future);
      if (runtime.status != VisionRuntimeStatus.ready) {
        await _ref.read(visionControllerProvider.notifier).start();
      }
    } on Object {
      // The accessible error state provides the explicit retry action.
    }
  }

  Future<void> start() async {
    await _ref.read(assistiveFeedbackControllerProvider.future);
    await _ref.read(visionControllerProvider.notifier).start();
    if (_isVisionReady) {
      await _ref.read(scanControllerProvider.notifier).start();
    }
  }

  Future<void> pause() async {
    final feedback = _ref.read(assistiveFeedbackControllerProvider.notifier);
    final camera = _ref.read(scanControllerProvider.notifier);
    final vision = _ref.read(visionControllerProvider.notifier);
    _resetProximity();
    await Future.wait<void>([
      feedback.stopAlerts(),
      camera.pause(),
      vision.stop(),
    ]);
  }

  Future<void> resume() => start();

  Future<void> stop() async {
    final feedback = _ref.read(assistiveFeedbackControllerProvider.notifier);
    final camera = _ref.read(scanControllerProvider.notifier);
    final vision = _ref.read(visionControllerProvider.notifier);
    _resetProximity();
    await Future.wait<void>([
      feedback.stopAlerts(),
      camera.stop(),
      vision.stop(),
    ]);
  }

  Future<void> handleBackground() async {
    final feedback = _ref.read(assistiveFeedbackControllerProvider.notifier);
    final camera = _ref.read(scanControllerProvider.notifier);
    final vision = _ref.read(visionControllerProvider.notifier);
    _resetProximity();
    await Future.wait<void>([
      feedback.stopAlerts(),
      camera.handleBackground(),
      vision.handleBackground(),
    ]);
  }

  Future<void> handleForeground() async {
    await _ref.read(visionControllerProvider.notifier).handleForeground();
    if (_isVisionReady) {
      await _ref.read(scanControllerProvider.notifier).handleForeground();
    }
  }

  Future<void> retryVision() async {
    final feedback = _ref.read(assistiveFeedbackControllerProvider.notifier);
    final camera = _ref.read(scanControllerProvider.notifier);
    final vision = _ref.read(visionControllerProvider.notifier);
    _resetProximity();
    await Future.wait<void>([feedback.stopAlerts(), camera.stop()]);
    await vision.retry();
  }

  void _resetProximity() {
    _ref.read(proximityControllerProvider.notifier).reset();
  }

  bool get _isVisionReady =>
      _ref.read(visionControllerProvider).asData?.value.status ==
      VisionRuntimeStatus.ready;
}

final Provider<AssistiveScanCoordinator> assistiveScanCoordinatorProvider =
    Provider<AssistiveScanCoordinator>(AssistiveScanCoordinator.new);
