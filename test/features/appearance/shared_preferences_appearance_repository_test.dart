import 'package:eyes_mobile/features/appearance/domain/appearance_preference.dart';
import 'package:eyes_mobile/features/appearance/infrastructure/shared_preferences_appearance_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test(
    'defaults to the system theme and stores a versioned preference',
    () async {
      final storage = SharedPreferencesAsync();
      final repository = SharedPreferencesAppearanceRepository(storage);

      expect(await repository.load(), AppearancePreference.system);
      await repository.save(AppearancePreference.highContrastDark);

      expect(await repository.load(), AppearancePreference.highContrastDark);
      expect(await storage.getKeys(), <String>{'appearance.preference.v1'});
    },
  );

  test('ignores unknown legacy values safely', () async {
    final storage = SharedPreferencesAsync();
    await storage.setString('appearance.preference.v1', 'unknown-theme');

    final repository = SharedPreferencesAppearanceRepository(storage);

    expect(await repository.load(), AppearancePreference.system);
  });
}
