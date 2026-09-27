import 'package:eyes_mobile/app/routing/app_router.dart';
import 'package:eyes_mobile/core/accessibility/accessible_feedback_service.dart';
import 'package:eyes_mobile/core/design_system/eyes_design_system.dart';
import 'package:eyes_mobile/core/error/app_error_reporter.dart';
import 'package:eyes_mobile/features/home/application/home_controller.dart';
import 'package:eyes_mobile/features/home/domain/home_state.dart';
import 'package:eyes_mobile/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(homeControllerProvider);

    return EyesPageScaffold(
      title: l10n.appName,
      maxContentWidth: 720,
      child: state.when(
        data: (HomeState data) => _HomeContent(state: data),
        error: (Object error, StackTrace stackTrace) => EyesStateView.error(
          title: l10n.unexpectedError,
          actionLabel: l10n.tryAgain,
          onAction: () => ref.invalidate(homeControllerProvider),
        ),
        loading: () => EyesStateView.loading(title: l10n.loading),
      ),
    );
  }
}

final class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final layout = context.eyesLayout;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        EyesPageHeader(
          title: l10n.homeTitle,
          description: l10n.foundationReady,
          leading: ExcludeSemantics(
            child: Icon(
              Icons.visibility_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 48,
            ),
          ),
        ),
        SizedBox(height: layout.spaceXl),
        EyesButton(
          label: l10n.openCamera,
          semanticHint: l10n.scanStartHint,
          onPressed: () => context.pushNamed(AppRoutes.camera),
          icon: Icons.center_focus_strong_outlined,
          expand: true,
        ),
        SizedBox(height: layout.spaceLg),
        EyesStatusBanner(
          title: l10n.homeOfflineTitle,
          message: l10n.homeOfflineMessage,
          tone: EyesStatusTone.success,
        ),
        SizedBox(height: layout.spaceLg),
        EyesSection(
          title: l10n.homeSupportTitle,
          description: l10n.homeSupportDescription,
          icon: Icons.tune_outlined,
          children: <Widget>[
            EyesActionTile(
              title: l10n.openFeedbackSettings,
              icon: Icons.volume_up_outlined,
              onTap: () => context.pushNamed(AppRoutes.settings),
            ),
            EyesActionTile(
              title: l10n.helpAndSafetyTitle,
              icon: Icons.help_outline,
              onTap: () => context.pushNamed(AppRoutes.help),
            ),
            EyesActionTile(
              title: l10n.openAccountSettings,
              subtitle: l10n.accountOptionalHeading,
              icon: Icons.account_circle_outlined,
              onTap: () => context.pushNamed(AppRoutes.account),
            ),
          ],
        ),
        SizedBox(height: layout.spaceLg),
        EyesButton(
          label: l10n.testFeedbackLabel,
          semanticHint: l10n.testFeedbackHint,
          icon: Icons.vibration,
          variant: EyesButtonVariant.outlined,
          expand: true,
          onPressed: () => _testFeedback(context, ref),
        ),
        if (state.feedbackMessage case final String message) ...<Widget>[
          SizedBox(height: layout.spaceLg),
          EyesStatusBanner(
            title: l10n.testFeedbackLabel,
            message: message,
            tone: EyesStatusTone.info,
            liveRegion: true,
          ),
        ],
      ],
    );
  }

  Future<void> _testFeedback(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(accessibleFeedbackServiceProvider).confirm();
      ref
          .read(homeControllerProvider.notifier)
          .markFeedbackDelivered(l10n.feedbackConfirmed);
    } on Object catch (error, stackTrace) {
      ref
          .read(appErrorReporterProvider)
          .capture(error, stackTrace, source: 'accessible-feedback');
      ref
          .read(homeControllerProvider.notifier)
          .markFeedbackDelivered(l10n.feedbackUnavailable);
    }
  }
}
