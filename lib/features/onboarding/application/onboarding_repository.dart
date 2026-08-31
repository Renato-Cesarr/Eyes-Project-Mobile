import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class OnboardingRepository {
  Future<bool> isCompleted();

  Future<void> markCompleted();
}

final Provider<OnboardingRepository> onboardingRepositoryProvider =
    Provider<OnboardingRepository>(
      (Ref ref) => throw StateError(
        'OnboardingRepository must be overridden at bootstrap.',
      ),
    );
