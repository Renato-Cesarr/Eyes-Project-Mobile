import 'package:eyes_mobile/features/onboarding/application/onboarding_repository.dart';

final class InMemoryOnboardingRepository implements OnboardingRepository {
  InMemoryOnboardingRepository({this.completed = false, this.failure});

  bool completed;
  final Object? failure;
  int completionWrites = 0;

  @override
  Future<bool> isCompleted() async {
    _throwIfConfigured();
    return completed;
  }

  @override
  Future<void> markCompleted() async {
    _throwIfConfigured();
    completed = true;
    completionWrites++;
  }

  void _throwIfConfigured() {
    final configuredFailure = failure;
    if (configuredFailure != null) {
      throw configuredFailure;
    }
  }
}
