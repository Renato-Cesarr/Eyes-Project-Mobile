import 'package:eyes_mobile/core/error/app_error_reporter.dart';
import 'package:eyes_mobile/features/onboarding/application/onboarding_repository.dart';
import 'package:eyes_mobile/features/onboarding/application/onboarding_state.dart';
import 'package:eyes_mobile/features/scanning/application/camera_gateway.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_permission_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class OnboardingController extends AsyncNotifier<OnboardingState> {
  @override
  Future<OnboardingState> build() async {
    try {
      final completed = await ref
          .read(onboardingRepositoryProvider)
          .isCompleted();
      return OnboardingState(completed: completed);
    } on Object catch (error, stackTrace) {
      _report(error, stackTrace, 'onboarding-load');
      rethrow;
    }
  }

  void begin() {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }
    state = AsyncData<OnboardingState>(
      current.copyWith(
        step: OnboardingStep.welcome,
        clearCameraPermission: true,
        operation: OnboardingOperation.idle,
      ),
    );
  }

  void next() => _move(1);

  void back() => _move(-1);

  Future<void> checkCameraPermission() async {
    final current = state.asData?.value;
    if (current == null || current.step != OnboardingStep.camera) {
      return;
    }
    try {
      final permission = await ref
          .read(cameraGatewayProvider)
          .checkPermission();
      _setPermission(permission);
    } on Object catch (error, stackTrace) {
      _report(error, stackTrace, 'onboarding-camera-check');
    }
  }

  Future<void> requestCameraPermission() async {
    final current = state.asData?.value;
    if (current == null || current.isBusy) {
      return;
    }
    state = AsyncData<OnboardingState>(
      current.copyWith(operation: OnboardingOperation.requestingPermission),
    );
    try {
      final permission = await ref
          .read(cameraGatewayProvider)
          .requestPermission();
      _setPermission(permission);
    } on Object catch (error, stackTrace) {
      _report(error, stackTrace, 'onboarding-camera-request');
      _setPermission(CameraPermissionState.denied);
    }
  }

  Future<void> openDeviceSettings() async {
    final current = state.asData?.value;
    if (current == null || current.isBusy) {
      return;
    }
    state = AsyncData<OnboardingState>(
      current.copyWith(operation: OnboardingOperation.openingSettings),
    );
    try {
      await ref.read(cameraGatewayProvider).openSettings();
    } on Object catch (error, stackTrace) {
      _report(error, stackTrace, 'onboarding-open-settings');
    } finally {
      final latest = state.asData?.value;
      if (latest != null) {
        state = AsyncData<OnboardingState>(
          latest.copyWith(operation: OnboardingOperation.idle),
        );
      }
    }
  }

  Future<void> complete() async {
    final current = state.asData?.value;
    if (current == null || current.isBusy) {
      return;
    }
    state = AsyncData<OnboardingState>(
      current.copyWith(operation: OnboardingOperation.saving),
    );
    try {
      await ref.read(onboardingRepositoryProvider).markCompleted();
      state = AsyncData<OnboardingState>(
        current.copyWith(completed: true, operation: OnboardingOperation.idle),
      );
    } on Object catch (error, stackTrace) {
      _report(error, stackTrace, 'onboarding-save');
      state = AsyncError<OnboardingState>(error, stackTrace);
    }
  }

  void _move(int delta) {
    final current = state.asData?.value;
    if (current == null || current.isBusy) {
      return;
    }
    final target = (current.step.index + delta).clamp(
      0,
      OnboardingStep.values.length - 1,
    );
    state = AsyncData<OnboardingState>(
      current.copyWith(step: OnboardingStep.values[target]),
    );
  }

  void _setPermission(CameraPermissionState permission) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }
    state = AsyncData<OnboardingState>(
      current.copyWith(
        cameraPermission: permission,
        operation: OnboardingOperation.idle,
      ),
    );
  }

  void _report(Object error, StackTrace stackTrace, String source) {
    ref
        .read(appErrorReporterProvider)
        .capture(error, stackTrace, source: source);
  }
}

final AsyncNotifierProvider<OnboardingController, OnboardingState>
onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );
