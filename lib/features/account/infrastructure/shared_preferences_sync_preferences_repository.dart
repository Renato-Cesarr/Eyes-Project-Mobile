import 'package:eyes_mobile/features/account/application/sync_preferences_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class SharedPreferencesSyncPreferencesRepository
    implements SyncPreferencesRepository {
  const SharedPreferencesSyncPreferencesRepository(this._preferences);

  static const String _consentKey = 'account.sync-consent.v1';

  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> readConsent() async =>
      await _preferences.getBool(_consentKey) ?? false;

  @override
  Future<void> writeConsent(bool value) =>
      _preferences.setBool(_consentKey, value);
}
