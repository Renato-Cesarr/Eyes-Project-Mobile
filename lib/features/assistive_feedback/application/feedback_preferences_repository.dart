import 'package:eyes_mobile/features/assistive_feedback/domain/feedback_preferences.dart';

abstract interface class FeedbackPreferencesRepository {
  Future<FeedbackPreferences> load();
  Future<void> save(FeedbackPreferences preferences);
  Future<void> clear();
}
