import 'package:eyes_mobile/core/persistence/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final usageTermsProvider = Provider<UsageTerms>(
  (ref) => UsageTerms(ref.read(sharedPreferencesProvider)),
);

final class UsageTerms {
  const UsageTerms(this._preferences);

  static const version = 1;
  static const _key = 'terms.accepted_version';
  final SharedPreferencesAsync _preferences;

  Future<bool> isAccepted() async => await _preferences.getInt(_key) == version;

  Future<void> accept() => _preferences.setInt(_key, version);
}
