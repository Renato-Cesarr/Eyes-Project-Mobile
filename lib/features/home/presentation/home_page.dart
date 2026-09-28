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
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(layout.spaceXl),
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(layout.radiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ExcludeSemantics(
                child: Icon(
                  Icons.visibility_outlined,
                  color: colors.onPrimary,
                  size: 32,
                ),
              ),
              SizedBox(height: layout.spaceLg),
              Semantics(
                header: true,
                child: Text(
                  l10n.homeTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(height: layout.spaceSm),
              Text(
                l10n.foundationReady,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: colors.onPrimary),
              ),
              SizedBox(height: layout.spaceXl),
              Semantics(
                hint: l10n.scanStartHint,
                child: FilledButton.icon(
                  onPressed: () => context.pushNamed(AppRoutes.camera),
                  icon: const Icon(Icons.center_focus_strong_outlined),
                  label: Text(l10n.openCamera),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: colors.onPrimary,
                    foregroundColor: colors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: layout.spaceLg),
        Semantics(
          container: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ExcludeSemantics(
                child: Icon(Icons.offline_bolt_outlined, color: colors.primary),
              ),
              SizedBox(width: layout.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.homeOfflineTitle,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      l10n.homeOfflineMessage,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: layout.spaceXl),
        const Divider(),
        SizedBox(height: layout.spaceSm),
        Semantics(
          header: true,
          child: Text(
            l10n.homeSupportTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        EyesActionTile(
          title: l10n.openFeedbackSettings,
          icon: Icons.volume_up_outlined,
          onTap: () => context.pushNamed(AppRoutes.settings),
        ),
        const Divider(height: 1),
        EyesActionTile(
          title: l10n.helpAndSafetyTitle,
          icon: Icons.help_outline,
          onTap: () => context.pushNamed(AppRoutes.help),
        ),
        const Divider(height: 1),
        EyesActionTile(
          title: l10n.openAccountSettings,
          subtitle: l10n.accountOptionalHeading,
          icon: Icons.account_circle_outlined,
          onTap: () => context.pushNamed(AppRoutes.account),
        ),
        SizedBox(height: layout.spaceXl),
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
