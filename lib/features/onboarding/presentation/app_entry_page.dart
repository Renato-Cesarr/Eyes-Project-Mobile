import 'package:eyes_mobile/core/design_system/eyes_design_system.dart';
import 'package:eyes_mobile/features/home/presentation/home_page.dart';
import 'package:eyes_mobile/features/onboarding/application/onboarding_controller.dart';
import 'package:eyes_mobile/features/onboarding/application/onboarding_state.dart';
import 'package:eyes_mobile/features/onboarding/presentation/onboarding_page.dart';
import 'package:eyes_mobile/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class AppEntryPage extends ConsumerWidget {
  const AppEntryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    return state.when(
      data: (OnboardingState value) =>
          value.completed ? const HomePage() : const OnboardingPage(),
      error: (Object error, StackTrace stackTrace) => _EntryError(
        onRetry: () => ref.invalidate(onboardingControllerProvider),
      ),
      loading: () => Scaffold(
        body: SafeArea(
          child: EyesStateView.loading(
            title: AppLocalizations.of(context).loading,
          ),
        ),
      ),
    );
  }
}

final class _EntryError extends StatelessWidget {
  const _EntryError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EyesPageScaffold(
      title: l10n.appName,
      scrollable: false,
      child: EyesStateView.error(
        title: l10n.onboardingLoadError,
        actionLabel: l10n.tryAgain,
        onAction: onRetry,
      ),
    );
  }
}
