import 'package:eyes_mobile/features/assistive_feedback/application/assistive_haptics.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/feedback_preferences_repository.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/speech_gateway.dart';
import 'package:eyes_mobile/features/assistive_feedback/domain/feedback_preferences.dart';

final class FakeSpeechGateway implements SpeechGateway {
  FakeSpeechGateway({this.failure});

  final Object? failure;
  final List<String> spoken = [];
  final List<SpeechConfiguration> configurations = [];
  int stopCalls = 0;

  @override
  Future<void> configure(SpeechConfiguration configuration) async {
    configurations.add(configuration);
    _throwIfConfigured();
  }

  @override
  Future<void> speak(String message) async {
    _throwIfConfigured();
    spoken.add(message);
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  @override
  Future<void> dispose() => stop();

  void _throwIfConfigured() {
    final configuredFailure = failure;
    if (configuredFailure != null) {
      throw configuredFailure;
    }
  }
}

final class FakeAssistiveHaptics implements AssistiveHaptics {
  FakeAssistiveHaptics({this.failure});

  final Object? failure;
  int confirmations = 0;
  int warnings = 0;
  int criticalAlerts = 0;

  @override
  Future<void> confirm() async {
    _throwIfConfigured();
    confirmations++;
  }

  @override
  Future<void> warning() async {
    _throwIfConfigured();
    warnings++;
  }

  @override
  Future<void> criticalAlert() async {
    _throwIfConfigured();
    criticalAlerts++;
  }

  void _throwIfConfigured() {
    final configuredFailure = failure;
    if (configuredFailure != null) {
      throw configuredFailure;
    }
  }
}

final class InMemoryFeedbackPreferencesRepository
    implements FeedbackPreferencesRepository {
  InMemoryFeedbackPreferencesRepository({
    this.preferences = FeedbackPreferences.defaults,
    this.failure,
  });

  FeedbackPreferences preferences;
  final Object? failure;
  int saves = 0;
  int clears = 0;

  @override
  Future<void> clear() async {
    _throwIfConfigured();
    clears++;
    preferences = FeedbackPreferences.defaults;
  }

  @override
  Future<FeedbackPreferences> load() async {
    _throwIfConfigured();
    return preferences;
  }

  @override
  Future<void> save(FeedbackPreferences preferences) async {
    _throwIfConfigured();
    saves++;
    this.preferences = preferences;
  }

  void _throwIfConfigured() {
    final configuredFailure = failure;
    if (configuredFailure != null) {
      throw configuredFailure;
    }
  }
}
