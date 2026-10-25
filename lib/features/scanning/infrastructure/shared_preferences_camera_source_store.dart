import 'package:eyes_mobile/features/scanning/application/camera_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class SharedPreferencesCameraSourceStore
    implements CameraSourcePreferenceStore {
  const SharedPreferencesCameraSourceStore(this._preferences);

  static const String _key = 'camera.source.preference.v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<CameraSourceKind?> load() async {
    final value = await _preferences.getString(_key);
    for (final kind in CameraSourceKind.values) {
      if (kind.name == value) return kind;
    }
    return null;
  }

  @override
  Future<void> save(CameraSourceKind kind) =>
      _preferences.setString(_key, kind.name);
}
