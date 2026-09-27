import 'package:eyes_mobile/features/appearance/domain/appearance_preference.dart';

enum AppearanceNotice { none, saved, saveFailed }

final class AppearanceState {
  const AppearanceState({
    this.preference = AppearancePreference.system,
    this.notice = AppearanceNotice.none,
  });

  final AppearancePreference preference;
  final AppearanceNotice notice;

  AppearanceState copyWith({
    AppearancePreference? preference,
    AppearanceNotice? notice,
  }) => AppearanceState(
    preference: preference ?? this.preference,
    notice: notice ?? this.notice,
  );
}
