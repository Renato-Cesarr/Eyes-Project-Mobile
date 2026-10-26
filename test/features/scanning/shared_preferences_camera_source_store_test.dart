import 'package:eyes_mobile/features/scanning/application/camera_source.dart';
import 'package:eyes_mobile/features/scanning/infrastructure/shared_preferences_camera_source_store.dart';
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
    'keeps automatic webcam priority until the user chooses a source',
    () async {
      final preferences = SharedPreferencesAsync();
      final store = SharedPreferencesCameraSourceStore(preferences);

      expect(await store.load(), isNull);
      await store.save(CameraSourceKind.phone);
      expect(await store.load(), CameraSourceKind.phone);
      expect(await preferences.getKeys(), {'camera.source.preference.v1'});
    },
  );

  test('ignores a stale preference value safely', () async {
    final preferences = SharedPreferencesAsync();
    await preferences.setString(
      'camera.source.preference.v1',
      'removed-source',
    );
    final store = SharedPreferencesCameraSourceStore(preferences);

    expect(await store.load(), isNull);
  });
}
