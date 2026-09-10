import 'package:eyes_mobile/features/onboarding/infrastructure/shared_preferences_onboarding_repository.dart';
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

  test('stores only the versioned local completion flag', () async {
    final storage = SharedPreferencesAsync();
    final repository = SharedPreferencesOnboardingRepository(storage);

    expect(await repository.isCompleted(), isFalse);
    await repository.markCompleted();

    expect(await repository.isCompleted(), isTrue);
    expect(await storage.getKeys(), <String>{'onboarding.completed.v1'});
  });
}
