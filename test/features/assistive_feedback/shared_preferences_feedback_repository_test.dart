import 'package:eyes_mobile/features/assistive_feedback/domain/feedback_preferences.dart';
import 'package:eyes_mobile/features/assistive_feedback/infrastructure/shared_preferences_feedback_repository.dart';
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

  test('persiste, restaura e remove somente preferências assistivas', () async {
    final storage = SharedPreferencesAsync();
    final repository = SharedPreferencesFeedbackRepository(storage);
    const custom = FeedbackPreferences(
      speechRate: 0.65,
      volume: 0.4,
      detailLevel: VoiceDetailLevel.detailed,
      announceAttention: false,
      sensitivity: AlertSensitivityPreset.fewerAlerts,
      hapticsEnabled: false,
    );

    await repository.save(custom);
    expect((await repository.load()).speechRate, 0.65);
    expect((await repository.load()).detailLevel, VoiceDetailLevel.detailed);
    expect(
      (await repository.load()).sensitivity,
      AlertSensitivityPreset.fewerAlerts,
    );

    await repository.clear();
    expect((await repository.load()).speechRate, 0.50);
    expect((await repository.load()).hapticsEnabled, isTrue);
  });

  test('ignora enum desconhecido e mantém padrão seguro', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          'feedback.voice.detail': 'future-option',
          'feedback.alerts.sensitivity': 'invalid',
        });
    final repository = SharedPreferencesFeedbackRepository(
      SharedPreferencesAsync(),
    );

    final result = await repository.load();

    expect(result.detailLevel, VoiceDetailLevel.concise);
    expect(result.sensitivity, AlertSensitivityPreset.balanced);
  });
}
