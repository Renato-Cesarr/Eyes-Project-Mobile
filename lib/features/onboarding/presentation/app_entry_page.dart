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
        body: Center(
          child: Semantics(
            liveRegion: true,
            label: AppLocalizations.of(context).loading,
            child: const CircularProgressIndicator(),
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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Semantics(
              liveRegion: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(l10n.onboardingLoadError, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: onRetry, child: Text(l10n.tryAgain)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
