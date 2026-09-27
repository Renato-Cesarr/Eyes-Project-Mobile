import 'package:eyes_mobile/features/appearance/domain/appearance_preference.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class AppearanceRepository {
  Future<AppearancePreference> load();

  Future<void> save(AppearancePreference preference);
}

final Provider<AppearanceRepository> appearanceRepositoryProvider =
    Provider<AppearanceRepository>(
      (Ref ref) => throw StateError(
        'AppearanceRepository must be overridden at bootstrap.',
      ),
    );
