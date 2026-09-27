import 'package:eyes_mobile/core/error/app_error_reporter.dart';
import 'package:eyes_mobile/features/appearance/application/appearance_repository.dart';
import 'package:eyes_mobile/features/appearance/application/appearance_state.dart';
import 'package:eyes_mobile/features/appearance/domain/appearance_preference.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class AppearanceController extends AsyncNotifier<AppearanceState> {
  @override
  Future<AppearanceState> build() async {
    try {
      final preference = await ref.read(appearanceRepositoryProvider).load();
      return AppearanceState(preference: preference);
    } on Object catch (error, stackTrace) {
      _report(error, stackTrace, 'appearance-load');
      return const AppearanceState(notice: AppearanceNotice.saveFailed);
    }
  }

  Future<void> select(AppearancePreference preference) async {
    final current = state.asData?.value;
    if (current == null || current.preference == preference) {
      return;
    }
    try {
      await ref.read(appearanceRepositoryProvider).save(preference);
      state = AsyncData<AppearanceState>(
        AppearanceState(preference: preference, notice: AppearanceNotice.saved),
      );
    } on Object catch (error, stackTrace) {
      _report(error, stackTrace, 'appearance-save');
      state = AsyncData<AppearanceState>(
        current.copyWith(notice: AppearanceNotice.saveFailed),
      );
    }
  }

  void clearNotice() {
    final current = state.asData?.value;
    if (current != null && current.notice != AppearanceNotice.none) {
      state = AsyncData<AppearanceState>(
        current.copyWith(notice: AppearanceNotice.none),
      );
    }
  }

  void _report(Object error, StackTrace stackTrace, String source) {
    ref
        .read(appErrorReporterProvider)
        .capture(error, stackTrace, source: source);
  }
}

final AsyncNotifierProvider<AppearanceController, AppearanceState>
appearanceControllerProvider =
    AsyncNotifierProvider<AppearanceController, AppearanceState>(
      AppearanceController.new,
    );
