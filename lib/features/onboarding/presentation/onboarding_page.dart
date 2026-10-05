import 'dart:async';

import 'package:eyes_mobile/app/routing/app_router.dart';
import 'package:eyes_mobile/core/design_system/eyes_design_system.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/assistive_feedback_controller.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/assistive_feedback_state.dart';
import 'package:eyes_mobile/features/onboarding/application/onboarding_controller.dart';
import 'package:eyes_mobile/features/onboarding/application/onboarding_state.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_permission_state.dart';
import 'package:eyes_mobile/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({this.replay = false, super.key});

  final bool replay;

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

final class _OnboardingPageState extends ConsumerState<OnboardingPage>
    with WidgetsBindingObserver {
  final FocusNode _headingFocus = FocusNode(debugLabel: 'onboarding-heading');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingControllerProvider.notifier).begin();
      _headingFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _headingFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(
        ref.read(onboardingControllerProvider.notifier).checkCameraPermission(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<OnboardingState>>(onboardingControllerProvider, (
      previous,
      next,
    ) {
      if (previous?.asData?.value.step != next.asData?.value.step) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _headingFocus.requestFocus();
          }
        });
      }
    });
    final l10n = AppLocalizations.of(context);
    final onboarding = ref.watch(onboardingControllerProvider);
    final feedback = ref.watch(assistiveFeedbackControllerProvider);

    return EyesPageScaffold(
      title: l10n.onboardingTitle,
      adaptiveTitle: true,
      leading: widget.replay
          ? IconButton(
              tooltip: l10n.close,
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.goNamed(AppRoutes.home),
              icon: const Icon(Icons.close),
            )
          : null,
      maxContentWidth: context.eyesLayout.readingMaxWidth,
      child: onboarding.when(
        data: (OnboardingState state) => _OnboardingContent(
          state: state,
          feedback: feedback,
          headingFocus: _headingFocus,
        ),
        error: (Object error, StackTrace stackTrace) => EyesStateView.error(
          title: l10n.onboardingLoadError,
          actionLabel: l10n.tryAgain,
          onAction: () => ref.invalidate(onboardingControllerProvider),
        ),
        loading: () => EyesStateView.loading(title: l10n.loading),
      ),
    );
  }
}

final class _OnboardingContent extends ConsumerWidget {
  const _OnboardingContent({
    required this.state,
    required this.feedback,
    required this.headingFocus,
  });

  final OnboardingState state;
  final AsyncValue<AssistiveFeedbackState> feedback;
  final FocusNode headingFocus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final content = _contentFor(l10n, state.step);
    final controller = ref.read(onboardingControllerProvider.notifier);

    final layout = context.eyesLayout;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          container: true,
          label: l10n.onboardingProgress(
            state.step.index + 1,
            OnboardingStep.values.length,
          ),
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                l10n.onboardingProgress(
                  state.step.index + 1,
                  OnboardingStep.values.length,
                ),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              SizedBox(height: layout.spaceSm),
              LinearProgressIndicator(
                value: (state.step.index + 1) / OnboardingStep.values.length,
              ),
            ],
          ),
        ),
        SizedBox(height: layout.spaceXl),
        Focus(
          focusNode: headingFocus,
          child: EyesPageHeader(
            title: content.title,
            description: content.body,
          ),
        ),
        if (state.step == OnboardingStep.feedback) ...<Widget>[
          SizedBox(height: layout.spaceXl),
          _FeedbackTests(feedback: feedback),
        ],
        if (state.step == OnboardingStep.privacy) ...<Widget>[
          SizedBox(height: layout.spaceXl),
          EyesButton(
            label: l10n.onboardingOptionalAccount,
            onPressed: state.isBusy
                ? null
                : () => context.pushNamed(
                    AppRoutes.account,
                    queryParameters: const <String, String>{
                      'source': 'onboarding',
                    },
                  ),
            icon: Icons.account_circle_outlined,
            variant: EyesButtonVariant.outlined,
            expand: true,
          ),
        ],
        if (state.step == OnboardingStep.camera) ...<Widget>[
          SizedBox(height: layout.spaceXl),
          _CameraPermissionStatus(state: state),
        ],
        SizedBox(height: layout.spaceXxl),
        _PrimaryOnboardingAction(state: state),
        if (state.step.index > 0) ...<Widget>[
          SizedBox(height: layout.spaceMd),
          EyesButton(
            label: l10n.back,
            onPressed: state.isBusy ? null : controller.back,
            variant: EyesButtonVariant.outlined,
            expand: true,
          ),
        ],
        if (state.step == OnboardingStep.camera &&
            state.cameraPermission !=
                CameraPermissionState.granted) ...<Widget>[
          SizedBox(height: layout.spaceMd),
          EyesButton(
            label: l10n.onboardingContinueWithoutCamera,
            onPressed: state.isBusy ? null : () => _complete(context, ref),
            variant: EyesButtonVariant.text,
            expand: true,
          ),
        ],
      ],
    );
  }
}

final class _FeedbackTests extends ConsumerWidget {
  const _FeedbackTests({required this.feedback});

  final AsyncValue<AssistiveFeedbackState> feedback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notice = feedback.asData?.value.notice;
    final noticeText = _feedbackNoticeText(l10n, notice);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        EyesButton(
          label: l10n.testVoice,
          onPressed: feedback.isLoading
              ? null
              : () => ref
                    .read(assistiveFeedbackControllerProvider.notifier)
                    .testVoice(l10n.voiceTestPhrase),
          icon: Icons.volume_up_outlined,
          variant: EyesButtonVariant.outlined,
          expand: true,
        ),
        SizedBox(height: context.eyesLayout.spaceMd),
        EyesButton(
          label: l10n.testHaptics,
          onPressed: feedback.isLoading
              ? null
              : ref
                    .read(assistiveFeedbackControllerProvider.notifier)
                    .testHaptics,
          icon: Icons.vibration_outlined,
          variant: EyesButtonVariant.outlined,
          expand: true,
        ),
        if (noticeText != null) ...<Widget>[
          SizedBox(height: context.eyesLayout.spaceLg),
          EyesStatusBanner(
            title: l10n.onboardingFeedbackTitle,
            message: noticeText,
            liveRegion: true,
          ),
        ],
      ],
    );
  }
}

final class _CameraPermissionStatus extends StatelessWidget {
  const _CameraPermissionStatus({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final permission = state.cameraPermission;
    if (permission == null) {
      return const SizedBox.shrink();
    }
    final text = switch (permission) {
      CameraPermissionState.granted => l10n.onboardingCameraGranted,
      CameraPermissionState.denied => l10n.onboardingCameraDenied,
      CameraPermissionState.permanentlyDenied =>
        l10n.onboardingCameraPermanentlyDenied,
      CameraPermissionState.restricted => l10n.onboardingCameraRestricted,
    };
    return Semantics(
      key: ValueKey<CameraPermissionState>(permission),
      container: true,
      liveRegion: true,
      label: text,
      excludeSemantics: true,
      child: EyesStatusBanner(
        title: l10n.onboardingCameraTitle,
        message: text,
        tone: permission == CameraPermissionState.granted
            ? EyesStatusTone.success
            : EyesStatusTone.warning,
        liveRegion: true,
      ),
    );
  }
}

final class _PrimaryOnboardingAction extends ConsumerWidget {
  const _PrimaryOnboardingAction({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final action = switch (state.step) {
      OnboardingStep.welcome ||
      OnboardingStep.safety ||
      OnboardingStep.privacy ||
      OnboardingStep.feedback => (
        label: l10n.next,
        onPressed: controller.next,
        icon: Icons.arrow_forward,
      ),
      OnboardingStep.camera => switch (state.cameraPermission) {
        CameraPermissionState.granted => (
          label: l10n.onboardingContinueOffline,
          onPressed: () => _complete(context, ref),
          icon: Icons.offline_bolt_outlined,
        ),
        CameraPermissionState.permanentlyDenied ||
        CameraPermissionState.restricted => (
          label: l10n.cameraOpenSettings,
          onPressed: controller.openDeviceSettings,
          icon: Icons.settings_outlined,
        ),
        _ => (
          label: state.cameraPermission == CameraPermissionState.denied
              ? l10n.onboardingTryCameraAgain
              : l10n.onboardingAllowCamera,
          onPressed: controller.requestCameraPermission,
          icon: Icons.camera_alt_outlined,
        ),
      },
    };

    return EyesButton(
      label: action.label,
      onPressed: state.isBusy ? null : action.onPressed,
      icon: action.icon,
      loading: state.isBusy,
      expand: true,
    );
  }
}

Future<void> _complete(BuildContext context, WidgetRef ref) async {
  await ref.read(onboardingControllerProvider.notifier).complete();
  if (context.mounted &&
      ref.read(onboardingControllerProvider).asData?.value.completed == true) {
    context.goNamed(AppRoutes.home);
  }
}

typedef _StepContent = ({String title, String body});

_StepContent _contentFor(AppLocalizations l10n, OnboardingStep step) =>
    switch (step) {
      OnboardingStep.welcome => (
        title: l10n.onboardingWelcomeTitle,
        body: l10n.onboardingWelcomeBody,
      ),
      OnboardingStep.safety => (
        title: l10n.onboardingSafetyTitle,
        body: l10n.onboardingSafetyBody,
      ),
      OnboardingStep.privacy => (
        title: l10n.onboardingPrivacyTitle,
        body: l10n.onboardingPrivacyBody,
      ),
      OnboardingStep.feedback => (
        title: l10n.onboardingFeedbackTitle,
        body: l10n.onboardingFeedbackBody,
      ),
      OnboardingStep.camera => (
        title: l10n.onboardingCameraTitle,
        body: l10n.onboardingCameraBody,
      ),
    };

String? _feedbackNoticeText(AppLocalizations l10n, FeedbackNotice? notice) =>
    switch (notice) {
      null || FeedbackNotice.none => null,
      FeedbackNotice.voiceTestSucceeded => l10n.voiceTestSucceeded,
      FeedbackNotice.hapticTestSucceeded => l10n.hapticTestSucceeded,
      FeedbackNotice.speechUnavailable => l10n.speechUnavailable,
      FeedbackNotice.hapticsUnavailable => l10n.hapticsUnavailable,
      FeedbackNotice.persistenceFailed => l10n.preferencesSaveFailed,
      FeedbackNotice.preferencesSaved => l10n.preferencesSaved,
      FeedbackNotice.defaultsRestored => l10n.defaultsRestored,
    };
