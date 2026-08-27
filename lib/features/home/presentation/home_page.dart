import 'package:eyes_mobile/app/routing/app_router.dart';
import 'package:eyes_mobile/core/accessibility/accessible_feedback_service.dart';
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
          error: (Object error, StackTrace stackTrace) =>
              _HomeError(onRetry: () => ref.invalidate(homeControllerProvider)),
          loading: () => Center(
            child: Semantics(
              label: l10n.loading,
              liveRegion: true,
              child: const CircularProgressIndicator(),
            ),
          ),
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
                FilledButton.icon(
                  onPressed: () => context.pushNamed(AppRoutes.camera),
                  icon: const ExcludeSemantics(
                    child: Icon(Icons.camera_alt_outlined),
                  ),
                  label: Text(l10n.openCamera),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.pushNamed(AppRoutes.settings),
                  icon: const ExcludeSemantics(
                    child: Icon(Icons.settings_outlined),
                  ),
                  label: Text(l10n.openFeedbackSettings),
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      l10n.accessibilityDescription,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Semantics(
                  button: true,
                  hint: l10n.testFeedbackHint,
                  label: l10n.testFeedbackLabel,
                  child: FilledButton.icon(
                    onPressed: () => _testFeedback(context, ref),
                    icon: const ExcludeSemantics(child: Icon(Icons.vibration)),
                    label: Text(l10n.testFeedbackLabel),
                  ),
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

final class _HomeError extends StatelessWidget {
  const _HomeError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(l10n.unexpectedError, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: Text(l10n.tryAgain)),
            ],
          ),
        ),
      ),
    );
  }
}
