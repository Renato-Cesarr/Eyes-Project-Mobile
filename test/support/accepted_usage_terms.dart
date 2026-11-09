import 'package:eyes_mobile/features/terms/application/usage_terms.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:shared_preferences/shared_preferences.dart';

Override acceptedUsageTerms() => usageTermsProvider.overrideWithValue(
  const UsageTerms(_AcceptedTermsPreferences()),
);

final class _AcceptedTermsPreferences implements SharedPreferencesAsync {
  const _AcceptedTermsPreferences();

  @override
  Future<int?> getInt(String key) async => UsageTerms.version;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
