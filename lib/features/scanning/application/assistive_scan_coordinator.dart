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
      final runtime = await _ref.read(visionControllerProvider.future);
      if (runtime.status != VisionRuntimeStatus.ready) {
        await _ref.read(visionControllerProvider.notifier).start();
      }
    } on Object {
      // The accessible error state provides the explicit retry action.
    }
  }

  Future<void> start() async {
    await _ref.read(visionControllerProvider.notifier).start();
    if (_isVisionReady) {
      await _ref.read(scanControllerProvider.notifier).start();
    }
  }

  Future<void> pause() async {
    _resetProximity();
    await _ref.read(scanControllerProvider.notifier).pause();
    await _ref.read(visionControllerProvider.notifier).stop();
  }

  Future<void> resume() => start();

  Future<void> stop() async {
    _resetProximity();
    final camera = _ref.read(scanControllerProvider.notifier);
    final vision = _ref.read(visionControllerProvider.notifier);
    await Future.wait<void>([camera.stop(), vision.stop()]);
  }

  Future<void> handleBackground() async {
    _resetProximity();
    await _ref.read(scanControllerProvider.notifier).handleBackground();
    await _ref.read(visionControllerProvider.notifier).handleBackground();
  }

  Future<void> handleForeground() async {
    await _ref.read(visionControllerProvider.notifier).handleForeground();
    if (_isVisionReady) {
      await _ref.read(scanControllerProvider.notifier).handleForeground();
    }
  }

  Future<void> retryVision() async {
    _resetProximity();
    await _ref.read(scanControllerProvider.notifier).stop();
    await _ref.read(visionControllerProvider.notifier).retry();
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
