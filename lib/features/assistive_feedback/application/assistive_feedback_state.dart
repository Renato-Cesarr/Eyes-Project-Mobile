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

final class AssistiveFeedbackState {
  const AssistiveFeedbackState({
    required this.preferences,
    this.notice = FeedbackNotice.none,
  });

  final FeedbackPreferences preferences;
  final FeedbackNotice notice;

  AssistiveFeedbackState copyWith({
    FeedbackPreferences? preferences,
    FeedbackNotice? notice,
  }) {
    return AssistiveFeedbackState(
      preferences: preferences ?? this.preferences,
      notice: notice ?? this.notice,
    );
  }
}
