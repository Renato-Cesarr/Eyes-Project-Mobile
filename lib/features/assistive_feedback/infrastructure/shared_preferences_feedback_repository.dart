import 'package:eyes_mobile/features/assistive_feedback/application/feedback_preferences_repository.dart';
import 'package:eyes_mobile/features/assistive_feedback/domain/feedback_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class SharedPreferencesFeedbackRepository
    implements FeedbackPreferencesRepository {
  const SharedPreferencesFeedbackRepository(this._preferences);

  static const String _rateKey = 'feedback.voice.rate';
  static const String _volumeKey = 'feedback.voice.volume';
  static const String _detailKey = 'feedback.voice.detail';
  static const String _attentionKey = 'feedback.alerts.attention';
  static const String _sensitivityKey = 'feedback.alerts.sensitivity';
  static const String _hapticsKey = 'feedback.haptics.enabled';

  static const Set<String> _keys = {
    _rateKey,
    _volumeKey,
    _detailKey,
    _attentionKey,
    _sensitivityKey,
    _hapticsKey,
  };

  final SharedPreferencesAsync _preferences;

  @override
  Future<FeedbackPreferences> load() async {
    final values = await Future.wait<Object?>([
      _preferences.getDouble(_rateKey),
      _preferences.getDouble(_volumeKey),
      _preferences.getString(_detailKey),
      _preferences.getBool(_attentionKey),
      _preferences.getString(_sensitivityKey),
      _preferences.getBool(_hapticsKey),
    ]);
    final defaults = FeedbackPreferences.defaults;
    return defaults.copyWith(
      speechRate: values[0] as double?,
      volume: values[1] as double?,
      detailLevel: _enumValue(
        VoiceDetailLevel.values,
        values[2] as String?,
        defaults.detailLevel,
      ),
      announceAttention: values[3] as bool?,
      sensitivity: _enumValue(
        AlertSensitivityPreset.values,
        values[4] as String?,
        defaults.sensitivity,
      ),
      hapticsEnabled: values[5] as bool?,
    );
  }

  @override
  Future<void> save(FeedbackPreferences preferences) async {
    await Future.wait<void>([
      _preferences.setDouble(_rateKey, preferences.speechRate),
      _preferences.setDouble(_volumeKey, preferences.volume),
      _preferences.setString(_detailKey, preferences.detailLevel.name),
      _preferences.setBool(_attentionKey, preferences.announceAttention),
      _preferences.setString(_sensitivityKey, preferences.sensitivity.name),
      _preferences.setBool(_hapticsKey, preferences.hapticsEnabled),
    ]);
  }

  @override
  Future<void> clear() => _preferences.clear(allowList: _keys);

  T _enumValue<T extends Enum>(List<T> values, String? name, T fallback) {
    return values.where((value) => value.name == name).firstOrNull ?? fallback;
  }
}
