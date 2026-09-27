import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:eyes_mobile/core/error/app_error_reporter.dart';
import 'package:eyes_mobile/core/logging/secure_logger.dart';
import 'package:eyes_mobile/features/appearance/application/appearance_controller.dart';
import 'package:eyes_mobile/features/appearance/application/appearance_repository.dart';
import 'package:eyes_mobile/features/appearance/application/appearance_state.dart';
import 'package:eyes_mobile/features/appearance/domain/appearance_preference.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_appearance.dart';

void main() {
  test('loads and persists the selected accessible appearance', () async {
    final repository = InMemoryAppearanceRepository(
      preference: AppearancePreference.dark,
    );
    final container = _container(repository);
    addTearDown(container.dispose);

    expect(
      (await container.read(appearanceControllerProvider.future)).preference,
      AppearancePreference.dark,
    );

    await container
        .read(appearanceControllerProvider.notifier)
        .select(AppearancePreference.highContrastLight);

    final state = container.read(appearanceControllerProvider).requireValue;
    expect(state.preference, AppearancePreference.highContrastLight);
    expect(state.notice, AppearanceNotice.saved);
    expect(repository.preference, AppearancePreference.highContrastLight);
    expect(repository.saveCalls, 1);
  });

  test('keeps the previous appearance when persistence fails', () async {
    final repository = InMemoryAppearanceRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(appearanceControllerProvider.future);
    repository.failure = StateError('disk unavailable');

    await container
        .read(appearanceControllerProvider.notifier)
        .select(AppearancePreference.dark);

    final state = container.read(appearanceControllerProvider).requireValue;
    expect(state.preference, AppearancePreference.system);
    expect(state.notice, AppearanceNotice.saveFailed);
  });
}

ProviderContainer _container(InMemoryAppearanceRepository repository) {
  final logger = SecureLogger(AppEnvironment.dev());
  return ProviderContainer(
    overrides: [
      appErrorReporterProvider.overrideWithValue(AppErrorReporter(logger)),
      appearanceRepositoryProvider.overrideWithValue(repository),
    ],
  );
}
