import 'package:eyes_mobile/core/error/app_error_reporter.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/assistive_feedback_controller.dart';
import 'package:eyes_mobile/features/object_detection/application/vision_controller.dart';
import 'package:eyes_mobile/features/object_detection/application/vision_runtime_state.dart';
import 'package:eyes_mobile/features/proximity/application/proximity_controller.dart';
import 'package:eyes_mobile/features/scanning/application/scan_controller.dart';
import 'package:eyes_mobile/features/scanning/application/scan_transition_feedback.dart';
import 'package:eyes_mobile/features/scanning/application/scan_wake_lock_gateway.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_scan_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Coordinates camera and local AI so frames are never produced without a
/// ready consumer and both native resources share the same lifecycle.
final class AssistiveScanCoordinator {
  const AssistiveScanCoordinator(this._ref);

  final Ref _ref;

  Future<void> prepare() async {
    await _setWakeLock(enabled: false);
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
    final wasStreaming = _isCameraStreaming;
    await _ref.read(assistiveFeedbackControllerProvider.future);
    await _ref.read(visionControllerProvider.notifier).start();
    if (_isVisionReady) {
      await _ref.read(scanControllerProvider.notifier).start();
    }
    await _synchronizeWakeLock();
    if (!wasStreaming && _isCameraStreaming) {
      await _deliverTransition(ScanTransition.started);
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
    await _setWakeLock(enabled: false);
    await _deliverTransition(ScanTransition.paused);
  }

  Future<void> resume() => start();

  Future<void> stop({bool announce = true}) async {
    final hadActiveSession =
        _isCameraStreaming ||
        _ref.read(scanControllerProvider).asData?.value.status ==
            CameraScanStatus.paused;
    final feedback = _ref.read(assistiveFeedbackControllerProvider.notifier);
    final camera = _ref.read(scanControllerProvider.notifier);
    final vision = _ref.read(visionControllerProvider.notifier);
    final wakeLock = _ref.read(scanWakeLockGatewayProvider);
    final transitionFeedback = announce
        ? _ref.read(scanTransitionFeedbackProvider)
        : null;
    final errorReporter = _ref.read(appErrorReporterProvider);
    _resetProximity();
    await Future.wait<void>([
      feedback.stopAlerts(),
      camera.stop(),
      vision.stop(),
    ]);
    await _setWakeLockWith(wakeLock, errorReporter, enabled: false);
    if (announce && hadActiveSession) {
      await _deliverTransitionWith(
        transitionFeedback!,
        errorReporter,
        ScanTransition.ended,
      );
    }
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
    await _setWakeLock(enabled: false);
  }

  Future<void> handleForeground() async {
    await _ref.read(visionControllerProvider.notifier).handleForeground();
    if (_isVisionReady) {
      await _ref.read(scanControllerProvider.notifier).handleForeground();
    }
    await _synchronizeWakeLock();
  }

  Future<void> retryVision() async {
    final feedback = _ref.read(assistiveFeedbackControllerProvider.notifier);
    final camera = _ref.read(scanControllerProvider.notifier);
    final vision = _ref.read(visionControllerProvider.notifier);
    _resetProximity();
    await _setWakeLock(enabled: false);
    await Future.wait<void>([feedback.stopAlerts(), camera.stop()]);
    await vision.retry();
  }

  void _resetProximity() {
    _ref.read(proximityControllerProvider.notifier).reset();
  }

  bool get _isVisionReady =>
      _ref.read(visionControllerProvider).asData?.value.status ==
      VisionRuntimeStatus.ready;

  bool get _isCameraStreaming =>
      _ref.read(scanControllerProvider).asData?.value.status ==
      CameraScanStatus.streaming;

  Future<void> _synchronizeWakeLock() =>
      _setWakeLock(enabled: _isVisionReady && _isCameraStreaming);

  Future<void> _setWakeLock({required bool enabled}) async {
    final gateway = _ref.read(scanWakeLockGatewayProvider);
    final errorReporter = _ref.read(appErrorReporterProvider);
    await _setWakeLockWith(gateway, errorReporter, enabled: enabled);
  }

  Future<void> _setWakeLockWith(
    ScanWakeLockGateway gateway,
    AppErrorReporter errorReporter, {
    required bool enabled,
  }) async {
    try {
      if (enabled) {
        await gateway.enable();
      } else {
        await gateway.disable();
      }
    } on Object catch (error, stackTrace) {
      errorReporter.capture(
        error,
        stackTrace,
        source: 'scan-wake-lock',
        diagnosticCode: enabled
            ? 'wake-lock-enable-failed'
            : 'wake-lock-disable-failed',
      );
    }
  }

  Future<void> _deliverTransition(ScanTransition transition) async {
    final feedback = _ref.read(scanTransitionFeedbackProvider);
    final errorReporter = _ref.read(appErrorReporterProvider);
    await _deliverTransitionWith(feedback, errorReporter, transition);
  }

  Future<void> _deliverTransitionWith(
    ScanTransitionFeedback feedback,
    AppErrorReporter errorReporter,
    ScanTransition transition,
  ) async {
    try {
      await feedback.deliver(transition);
    } on Object catch (error, stackTrace) {
      errorReporter.capture(
        error,
        stackTrace,
        source: 'scan-transition-feedback',
        diagnosticCode: 'scan-${transition.name}-feedback-failed',
      );
    }
  }
}

final Provider<AssistiveScanCoordinator> assistiveScanCoordinatorProvider =
    Provider<AssistiveScanCoordinator>(AssistiveScanCoordinator.new);
