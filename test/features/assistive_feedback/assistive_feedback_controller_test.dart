import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:eyes_mobile/core/error/app_error_reporter.dart';
import 'package:eyes_mobile/core/logging/secure_logger.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/assistive_feedback_controller.dart';
import 'package:eyes_mobile/features/assistive_feedback/domain/feedback_preferences.dart';
import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_assistive_feedback.dart';

void main() {
  test(
    'carrega preferências, anuncia alerta e reforça crítico por vibração',
    () async {
      final speech = FakeSpeechGateway();
      final haptics = FakeAssistiveHaptics();
      final repository = InMemoryFeedbackPreferencesRepository();
      final container = _container(speech, haptics, repository);
      addTearDown(container.dispose);
      await container.read(assistiveFeedbackControllerProvider.future);

      container
          .read(assistiveFeedbackControllerProvider.notifier)
          .handleAlert(_event());
      await Future<void>.delayed(Duration.zero);

      expect(speech.spoken, ['Cadeira muito próxima, à direita. Cuidado.']);
      expect(haptics.criticalAlerts, 1);
    },
  );

  test('preferência desativa vibração e alertas de atenção', () async {
    final speech = FakeSpeechGateway();
    final haptics = FakeAssistiveHaptics();
    final repository = InMemoryFeedbackPreferencesRepository(
      preferences: const FeedbackPreferences(
        announceAttention: false,
        hapticsEnabled: false,
      ),
    );
    final container = _container(speech, haptics, repository);
    addTearDown(container.dispose);
    await container.read(assistiveFeedbackControllerProvider.future);
    final controller = container.read(
      assistiveFeedbackControllerProvider.notifier,
    );

    controller.handleAlert(_event(band: ProximityBand.attention));
    controller.handleAlert(_event());
    await Future<void>.delayed(Duration.zero);

    expect(speech.spoken, ['Cadeira muito próxima, à direita. Cuidado.']);
    expect(haptics.criticalAlerts, 0);
  });

  test('salva preferências tipadas sem armazenar dados sensíveis', () async {
    final repository = InMemoryFeedbackPreferencesRepository();
    final container = _container(
      FakeSpeechGateway(),
      FakeAssistiveHaptics(),
      repository,
    );
    addTearDown(container.dispose);
    await container.read(assistiveFeedbackControllerProvider.future);

    await container
        .read(assistiveFeedbackControllerProvider.notifier)
        .updatePreferences(
          const FeedbackPreferences(
            speechRate: 0.60,
            sensitivity: AlertSensitivityPreset.fewerAlerts,
          ),
        );

    expect(repository.saves, 1);
    expect(repository.preferences.speechRate, 0.60);
    expect(
      repository.preferences.sensitivity,
      AlertSensitivityPreset.fewerAlerts,
    );
  });

  test(
    'falha do TTS não impede salvar e aplicar outras preferências',
    () async {
      final repository = InMemoryFeedbackPreferencesRepository();
      final container = _container(
        FakeSpeechGateway(failure: StateError('tts missing')),
        FakeAssistiveHaptics(),
        repository,
      );
      addTearDown(container.dispose);
      await container.read(assistiveFeedbackControllerProvider.future);

      await container
          .read(assistiveFeedbackControllerProvider.notifier)
          .updatePreferences(
            const FeedbackPreferences(
              announceAttention: false,
              hapticsEnabled: false,
            ),
          );

      expect(repository.saves, 1);
      expect(repository.preferences.hapticsEnabled, isFalse);
      expect(
        container
            .read(assistiveFeedbackControllerProvider)
            .requireValue
            .preferences
            .announceAttention,
        isFalse,
      );
    },
  );
}

ProviderContainer _container(
  FakeSpeechGateway speech,
  FakeAssistiveHaptics haptics,
  InMemoryFeedbackPreferencesRepository repository,
) {
  final logger = SecureLogger(AppEnvironment.dev());
  return ProviderContainer(
    overrides: [
      appErrorReporterProvider.overrideWithValue(AppErrorReporter(logger)),
      speechGatewayProvider.overrideWithValue(speech),
      assistiveHapticsProvider.overrideWithValue(haptics),
      feedbackPreferencesRepositoryProvider.overrideWithValue(repository),
    ],
  );
}

ProximityAlertEvent _event({ProximityBand band = ProximityBand.veryNear}) {
  return ProximityAlertEvent(
    trackId: 1,
    kind: DetectedObjectKind.chair,
    band: band,
    direction: ProximityDirection.right,
    score: 0.9,
    priority: band == ProximityBand.veryNear ? 210 : 110,
    occurredAt: DateTime.utc(2026),
  );
}
