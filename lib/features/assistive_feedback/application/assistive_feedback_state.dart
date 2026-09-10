import 'package:eyes_mobile/features/assistive_feedback/domain/feedback_preferences.dart';

enum FeedbackNotice {
  none,
  preferencesSaved,
  defaultsRestored,
  voiceTestSucceeded,
  hapticTestSucceeded,
  speechUnavailable,
  hapticsUnavailable,
  persistenceFailed,
}

enum FeedbackChannelAvailability { available, unavailable }

final class AssistiveFeedbackState {
  const AssistiveFeedbackState({
    required this.preferences,
    required this.speechAvailability,
    required this.hapticsAvailability,
    this.notice = FeedbackNotice.none,
  });

  final FeedbackPreferences preferences;
  final FeedbackChannelAvailability speechAvailability;
  final FeedbackChannelAvailability hapticsAvailability;
  final FeedbackNotice notice;

  AssistiveFeedbackState copyWith({
    FeedbackPreferences? preferences,
    FeedbackChannelAvailability? speechAvailability,
    FeedbackChannelAvailability? hapticsAvailability,
    FeedbackNotice? notice,
  }) {
    return AssistiveFeedbackState(
      preferences: preferences ?? this.preferences,
      speechAvailability: speechAvailability ?? this.speechAvailability,
      hapticsAvailability: hapticsAvailability ?? this.hapticsAvailability,
      notice: notice ?? this.notice,
    );
  }
}
