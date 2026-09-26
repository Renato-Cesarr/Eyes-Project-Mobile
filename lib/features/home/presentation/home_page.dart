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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName)),
      body: SafeArea(
        child: state.when(
          data: (HomeState data) => _HomeContent(state: data),
          error: (Object error, StackTrace stackTrace) => EyesStateView.error(
            title: l10n.unexpectedError,
            actionLabel: l10n.tryAgain,
            onAction: () => ref.invalidate(homeControllerProvider),
          ),
          loading: () => EyesStateView.loading(title: l10n.loading),
        ),
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

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ExcludeSemantics(
                  child: Icon(
                    Icons.visibility_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 72,
                  ),
                ),
                const SizedBox(height: 24),
                EyesButton(
                  label: l10n.openCamera,
                  onPressed: () => context.pushNamed(AppRoutes.camera),
                  icon: Icons.camera_alt_outlined,
                  expand: true,
                ),
                const SizedBox(height: 12),
                EyesButton(
                  label: l10n.openFeedbackSettings,
                  onPressed: () => context.pushNamed(AppRoutes.settings),
                  icon: Icons.settings_outlined,
                  variant: EyesButtonVariant.outlined,
                  expand: true,
                ),
                const SizedBox(height: 12),
                EyesButton(
                  label: l10n.openAccountSettings,
                  onPressed: () => context.pushNamed(AppRoutes.account),
                  icon: Icons.account_circle_outlined,
                  variant: EyesButtonVariant.outlined,
                  expand: true,
                ),
                const SizedBox(height: 12),
                Semantics(
                  header: true,
                  child: Text(
                    l10n.homeTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.foundationReady,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                EyesCard(
                  child: Text(
                    l10n.accessibilityDescription,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 24),
                EyesButton(
                  label: l10n.testFeedbackLabel,
                  semanticHint: l10n.testFeedbackHint,
                  icon: Icons.vibration,
                  expand: true,
                  onPressed: () => _testFeedback(context, ref),
                ),
                if (state.feedbackMessage
                    case final String message) ...<Widget>[
                  const SizedBox(height: 20),
                  Semantics(
                    label: message,
                    liveRegion: true,
                    child: Text(
                      message,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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
