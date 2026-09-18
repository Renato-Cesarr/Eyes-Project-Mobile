import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class SyncPreferencesRepository {
  Future<bool> readConsent();

  Future<void> writeConsent(bool value);
}

final Provider<SyncPreferencesRepository> syncPreferencesRepositoryProvider =
    Provider<SyncPreferencesRepository>((Ref ref) {
      throw StateError(
        'SyncPreferencesRepository must be configured at bootstrap.',
      );
    });
