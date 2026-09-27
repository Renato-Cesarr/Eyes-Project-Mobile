import 'package:eyes_mobile/features/appearance/application/appearance_repository.dart';
import 'package:eyes_mobile/features/appearance/domain/appearance_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class SharedPreferencesAppearanceRepository
    implements AppearanceRepository {
  const SharedPreferencesAppearanceRepository(this._preferences);

  static const String _preferenceKey = 'appearance.preference.v1';

  final SharedPreferencesAsync _preferences;

  @override
  Future<AppearancePreference> load() async {
    final stored = await _preferences.getString(_preferenceKey);
    return AppearancePreference.values.firstWhere(
      (AppearancePreference value) => value.name == stored,
      orElse: () => AppearancePreference.system,
    );
  }

  @override
  Future<void> save(AppearancePreference preference) =>
      _preferences.setString(_preferenceKey, preference.name);
}
