import 'package:eyes_mobile/features/onboarding/application/onboarding_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class SharedPreferencesOnboardingRepository
    implements OnboardingRepository {
  const SharedPreferencesOnboardingRepository(this._preferences);

  static const String _completedKey = 'onboarding.completed.v1';

  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> isCompleted() async =>
      await _preferences.getBool(_completedKey) ?? false;

  @override
  Future<void> markCompleted() => _preferences.setBool(_completedKey, true);
}
