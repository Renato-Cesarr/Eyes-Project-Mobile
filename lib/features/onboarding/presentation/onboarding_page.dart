import 'dart:async';

import 'package:eyes_mobile/app/routing/app_router.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.onboardingTitle),
        leading: widget.replay
            ? IconButton(
                tooltip: l10n.close,
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.goNamed(AppRoutes.home),
                icon: const Icon(Icons.close),
              )
            : null,
      ),
      body: SafeArea(
        child: onboarding.when(
          data: (OnboardingState state) => _OnboardingContent(
            state: state,
            feedback: feedback,
            headingFocus: _headingFocus,
          ),
          error: (Object error, StackTrace stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Semantics(
                liveRegion: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(l10n.onboardingLoadError, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          ref.invalidate(onboardingControllerProvider),
                      child: Text(l10n.tryAgain),
                    ),
                  ],
                ),
              ),
            ),
          ),
          loading: () => Center(
            child: Semantics(
              liveRegion: true,
              label: l10n.loading,
              child: const CircularProgressIndicator(),
            ),
          ),
        ),
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

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Semantics(
                  container: true,
                  label: l10n.onboardingProgress(
                    state.step.index + 1,
                    OnboardingStep.values.length,
                  ),
                  excludeSemantics: true,
                  child: LinearProgressIndicator(
                    value:
                        (state.step.index + 1) / OnboardingStep.values.length,
                  ),
                ),
                const SizedBox(height: 28),
                ExcludeSemantics(child: Icon(content.icon, size: 64)),
                const SizedBox(height: 20),
                Focus(
                  focusNode: headingFocus,
                  child: Semantics(
                    header: true,
                    child: Text(
                      content.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  content.body,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                if (state.step == OnboardingStep.feedback) ...<Widget>[
                  const SizedBox(height: 24),
                  _FeedbackTests(feedback: feedback),
                ],
                if (state.step == OnboardingStep.camera) ...<Widget>[
                  const SizedBox(height: 24),
                  _CameraPermissionStatus(state: state),
                ],
                const SizedBox(height: 32),
                _PrimaryOnboardingAction(state: state),
                if (state.step.index > 0) ...<Widget>[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: state.isBusy ? null : controller.back,
                    child: Text(l10n.back),
                  ),
                ],
                if (state.step == OnboardingStep.camera &&
                    state.cameraPermission !=
                        CameraPermissionState.granted) ...<Widget>[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: state.isBusy
                        ? null
                        : () => _complete(context, ref),
                    child: Text(l10n.onboardingContinueWithoutCamera),
                  ),
                ],
              ],
            ),
          ),
        ),
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
        FilledButton.tonalIcon(
          onPressed: feedback.isLoading
              ? null
              : () => ref
                    .read(assistiveFeedbackControllerProvider.notifier)
                    .testVoice(l10n.voiceTestPhrase),
          icon: const ExcludeSemantics(child: Icon(Icons.volume_up_outlined)),
          label: Text(l10n.testVoice),
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: feedback.isLoading
              ? null
              : ref
                    .read(assistiveFeedbackControllerProvider.notifier)
                    .testHaptics,
          icon: const ExcludeSemantics(child: Icon(Icons.vibration_outlined)),
          label: Text(l10n.testHaptics),
        ),
        if (noticeText != null) ...<Widget>[
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(noticeText, textAlign: TextAlign.center),
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
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ExcludeSemantics(
                child: Icon(
                  permission == CameraPermissionState.granted
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(text)),
            ],
          ),
        ),
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

    return Semantics(
      button: true,
      enabled: !state.isBusy,
      label: action.label,
      excludeSemantics: true,
      child: FilledButton.icon(
        onPressed: state.isBusy ? null : action.onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 64),
        ),
        icon: ExcludeSemantics(
          child: state.isBusy
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(action.icon),
        ),
        label: Text(action.label),
      ),
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

typedef _StepContent = ({String title, String body, IconData icon});

_StepContent _contentFor(AppLocalizations l10n, OnboardingStep step) =>
    switch (step) {
      OnboardingStep.welcome => (
        title: l10n.onboardingWelcomeTitle,
        body: l10n.onboardingWelcomeBody,
        icon: Icons.visibility_outlined,
      ),
      OnboardingStep.safety => (
        title: l10n.onboardingSafetyTitle,
        body: l10n.onboardingSafetyBody,
        icon: Icons.health_and_safety_outlined,
      ),
      OnboardingStep.privacy => (
        title: l10n.onboardingPrivacyTitle,
        body: l10n.onboardingPrivacyBody,
        icon: Icons.privacy_tip_outlined,
      ),
      OnboardingStep.feedback => (
        title: l10n.onboardingFeedbackTitle,
        body: l10n.onboardingFeedbackBody,
        icon: Icons.record_voice_over_outlined,
      ),
      OnboardingStep.camera => (
        title: l10n.onboardingCameraTitle,
        body: l10n.onboardingCameraBody,
        icon: Icons.camera_alt_outlined,
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
