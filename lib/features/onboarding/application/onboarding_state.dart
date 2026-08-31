import 'package:eyes_mobile/features/scanning/domain/camera_permission_state.dart';

enum OnboardingStep { welcome, safety, privacy, feedback, camera }

enum OnboardingOperation { idle, requestingPermission, openingSettings, saving }

final class OnboardingState {
  const OnboardingState({
    required this.completed,
    this.step = OnboardingStep.welcome,
    this.cameraPermission,
    this.operation = OnboardingOperation.idle,
  });

  final bool completed;
  final OnboardingStep step;
  final CameraPermissionState? cameraPermission;
  final OnboardingOperation operation;

  bool get isBusy => operation != OnboardingOperation.idle;

  OnboardingState copyWith({
    bool? completed,
    OnboardingStep? step,
    CameraPermissionState? cameraPermission,
    bool clearCameraPermission = false,
    OnboardingOperation? operation,
  }) {
    return OnboardingState(
      completed: completed ?? this.completed,
      step: step ?? this.step,
      cameraPermission: clearCameraPermission
          ? null
          : cameraPermission ?? this.cameraPermission,
      operation: operation ?? this.operation,
    );
  }
}
