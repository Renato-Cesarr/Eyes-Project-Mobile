import 'dart:async';

import 'package:eyes_mobile/core/error/app_error_reporter.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/assistive_feedback_state.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/assistive_haptics.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/feedback_preferences_repository.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/speech_gateway.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/voice_alert_queue.dart';
import 'package:eyes_mobile/features/assistive_feedback/domain/assistive_alert_message.dart';
import 'package:eyes_mobile/features/assistive_feedback/domain/feedback_preferences.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<SpeechGateway> speechGatewayProvider = Provider<SpeechGateway>(
  (Ref ref) => throw UnimplementedError('SpeechGateway não configurado.'),
);

final Provider<AssistiveHaptics> assistiveHapticsProvider =
    Provider<AssistiveHaptics>(
      (Ref ref) =>
          throw UnimplementedError('AssistiveHaptics não configurado.'),
    );

final Provider<FeedbackPreferencesRepository>
feedbackPreferencesRepositoryProvider = Provider<FeedbackPreferencesRepository>(
  (Ref ref) => throw UnimplementedError(
    'FeedbackPreferencesRepository não configurado.',
  ),
);

final class AssistiveFeedbackController
    extends AsyncNotifier<AssistiveFeedbackState> {
  VoiceAlertQueue? _queue;
  bool _disposed = false;

  @override
  Future<AssistiveFeedbackState> build() async {
    _disposed = false;
    final repository = ref.read(feedbackPreferencesRepositoryProvider);
    var preferences = FeedbackPreferences.defaults;
    var notice = FeedbackNotice.none;
    var speechAvailability = FeedbackChannelAvailability.available;
    var hapticsAvailability = FeedbackChannelAvailability.available;
    try {
      preferences = await repository.load();
    } on Object catch (error, stackTrace) {
      notice = FeedbackNotice.persistenceFailed;
      _report(error, stackTrace, 'feedback-preferences-load');
    }
    final gateway = ref.read(speechGatewayProvider);
    try {
      await gateway.configure(_speechConfiguration(preferences));
    } on Object catch (error, stackTrace) {
      notice = FeedbackNotice.speechUnavailable;
      speechAvailability = FeedbackChannelAvailability.unavailable;
      _report(error, stackTrace, 'tts-initialize');
    }
    try {
      final available = await ref.read(assistiveHapticsProvider).isAvailable();
      if (!available) {
        hapticsAvailability = FeedbackChannelAvailability.unavailable;
        if (notice == FeedbackNotice.none) {
          notice = FeedbackNotice.hapticsUnavailable;
        }
      }
    } on Object catch (error, stackTrace) {
      hapticsAvailability = FeedbackChannelAvailability.unavailable;
      if (notice == FeedbackNotice.none) {
        notice = FeedbackNotice.hapticsUnavailable;
      }
      _report(error, stackTrace, 'haptics-initialize');
    }
    _queue = VoiceAlertQueue(
      gateway,
      onSuccess: _markSpeechAvailable,
      onFailure: (error, stackTrace) {
        _report(error, stackTrace, 'tts-alert');
        _markSpeechUnavailable();
      },
    );
    ref.onDispose(() {
      _disposed = true;
      unawaited(_queue?.dispose());
      _queue = null;
    });
    return AssistiveFeedbackState(
      preferences: preferences,
      speechAvailability: speechAvailability,
      hapticsAvailability: hapticsAvailability,
      notice: notice,
    );
  }

  Future<void> updatePreferences(FeedbackPreferences preferences) async {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }
    var notice = FeedbackNotice.preferencesSaved;
    try {
      await ref.read(feedbackPreferencesRepositoryProvider).save(preferences);
    } on Object catch (error, stackTrace) {
      notice = FeedbackNotice.persistenceFailed;
      _report(error, stackTrace, 'feedback-preferences-save');
    }
    try {
      await ref
          .read(speechGatewayProvider)
          .configure(_speechConfiguration(preferences));
      _markSpeechAvailable();
    } on Object catch (error, stackTrace) {
      notice = FeedbackNotice.speechUnavailable;
      _report(error, stackTrace, 'tts-configure');
    }
    if (!_disposed) {
      state = AsyncData<AssistiveFeedbackState>(
        current.copyWith(
          preferences: preferences,
          speechAvailability: notice == FeedbackNotice.speechUnavailable
              ? FeedbackChannelAvailability.unavailable
              : FeedbackChannelAvailability.available,
          notice: notice,
        ),
      );
    }
  }

  Future<void> restoreDefaults() async {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }
    try {
      final repository = ref.read(feedbackPreferencesRepositoryProvider);
      await repository.clear();
      await ref
          .read(speechGatewayProvider)
          .configure(_speechConfiguration(FeedbackPreferences.defaults));
      if (!_disposed) {
        state = AsyncData<AssistiveFeedbackState>(
          current.copyWith(
            preferences: FeedbackPreferences.defaults,
            speechAvailability: FeedbackChannelAvailability.available,
            notice: FeedbackNotice.defaultsRestored,
          ),
        );
      }
    } on Object catch (error, stackTrace) {
      _report(error, stackTrace, 'feedback-preferences-restore');
      _setNotice(FeedbackNotice.persistenceFailed);
    }
  }

  Future<void> testVoice(String message) async {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }
    try {
      final gateway = ref.read(speechGatewayProvider);
      await gateway.configure(_speechConfiguration(current.preferences));
      await gateway.speak(message);
      _setChannelState(
        speechAvailability: FeedbackChannelAvailability.available,
        notice: FeedbackNotice.voiceTestSucceeded,
      );
    } on SpeechPlaybackInterruptedException {
      return;
    } on Object catch (error, stackTrace) {
      _report(error, stackTrace, 'tts-test');
      _markSpeechUnavailable();
    }
  }

  Future<void> testHaptics() async {
    final preferences = state.asData?.value.preferences;
    if (preferences == null || !preferences.hapticsEnabled) {
      return;
    }
    try {
      final haptics = ref.read(assistiveHapticsProvider);
      if (!await haptics.isAvailable()) {
        _markHapticsUnavailable();
        return;
      }
      await haptics.confirm();
      _setChannelState(
        hapticsAvailability: FeedbackChannelAvailability.available,
        notice: FeedbackNotice.hapticTestSucceeded,
      );
    } on Object catch (error, stackTrace) {
      _report(error, stackTrace, 'haptics-test');
      _markHapticsUnavailable();
    }
  }

  void handleAlert(ProximityAlertEvent event) {
    final preferences = state.asData?.value.preferences;
    if (preferences == null ||
        (!preferences.announceAttention &&
            event.band == ProximityBand.attention)) {
      return;
    }
    final message = AssistiveAlertMessageComposer.compose(
      event,
      preferences.detailLevel,
    );
    _queue?.enqueue(message);
    if (preferences.hapticsEnabled && event.isCritical) {
      unawaited(_deliverCriticalHaptic());
    }
  }

  Future<void> stopAlerts() async => _queue?.clear();

  Future<void> _deliverCriticalHaptic() async {
    try {
      await ref.read(assistiveHapticsProvider).criticalAlert();
      _markHapticsAvailable();
    } on Object catch (error, stackTrace) {
      _report(error, stackTrace, 'haptics-alert');
      _markHapticsUnavailable();
    }
  }

  SpeechConfiguration _speechConfiguration(FeedbackPreferences preferences) {
    return SpeechConfiguration(
      rate: preferences.speechRate,
      volume: preferences.volume,
    );
  }

  void _setNotice(FeedbackNotice notice) {
    _setChannelState(notice: notice);
  }

  void _markSpeechAvailable() {
    final current = state.asData?.value;
    if (current == null ||
        (current.speechAvailability == FeedbackChannelAvailability.available &&
            current.notice != FeedbackNotice.speechUnavailable)) {
      return;
    }
    _setChannelState(
      speechAvailability: FeedbackChannelAvailability.available,
      notice: current.notice == FeedbackNotice.speechUnavailable
          ? FeedbackNotice.none
          : null,
    );
  }

  void _markSpeechUnavailable() {
    _setChannelState(
      speechAvailability: FeedbackChannelAvailability.unavailable,
      notice: FeedbackNotice.speechUnavailable,
    );
  }

  void _markHapticsAvailable() {
    final current = state.asData?.value;
    if (current == null ||
        (current.hapticsAvailability == FeedbackChannelAvailability.available &&
            current.notice != FeedbackNotice.hapticsUnavailable)) {
      return;
    }
    _setChannelState(
      hapticsAvailability: FeedbackChannelAvailability.available,
      notice: current.notice == FeedbackNotice.hapticsUnavailable
          ? FeedbackNotice.none
          : null,
    );
  }

  void _markHapticsUnavailable() {
    _setChannelState(
      hapticsAvailability: FeedbackChannelAvailability.unavailable,
      notice: FeedbackNotice.hapticsUnavailable,
    );
  }

  void _setChannelState({
    FeedbackChannelAvailability? speechAvailability,
    FeedbackChannelAvailability? hapticsAvailability,
    FeedbackNotice? notice,
  }) {
    if (_disposed) {
      return;
    }
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData<AssistiveFeedbackState>(
        current.copyWith(
          speechAvailability: speechAvailability,
          hapticsAvailability: hapticsAvailability,
          notice: notice,
        ),
      );
    }
  }

  void _report(Object error, StackTrace stackTrace, String source) {
    ref
        .read(appErrorReporterProvider)
        .capture(error, stackTrace, source: source);
  }
}

final AsyncNotifierProvider<AssistiveFeedbackController, AssistiveFeedbackState>
assistiveFeedbackControllerProvider =
    AsyncNotifierProvider<AssistiveFeedbackController, AssistiveFeedbackState>(
      AssistiveFeedbackController.new,
    );
