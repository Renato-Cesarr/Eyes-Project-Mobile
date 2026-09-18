import 'dart:async';

import 'package:eyes_mobile/core/recovery/operational_failure.dart';
import 'package:eyes_mobile/core/session/remote_session.dart';
import 'package:eyes_mobile/core/session/remote_session_store.dart';
import 'package:eyes_mobile/features/account/application/account_state.dart';
import 'package:eyes_mobile/features/account/application/auth_gateway.dart';
import 'package:eyes_mobile/features/account/application/metadata_sync_queue.dart';
import 'package:eyes_mobile/features/account/application/sync_preferences_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class AccountController extends AsyncNotifier<AccountState> {
  StreamSubscription<RemoteSessionChange>? _sessionSubscription;

  @override
  Future<AccountState> build() async {
    final sessionStore = ref.watch(remoteSessionStoreProvider);
    final preferences = ref.watch(syncPreferencesRepositoryProvider);
    _sessionSubscription ??= sessionStore.changes.listen(_onSessionChanged);
    ref.onDispose(() => unawaited(_sessionSubscription?.cancel()));
    final values = await Future.wait<Object?>(<Future<Object?>>[
      sessionStore.read(),
      preferences.readConsent(),
    ]);
    return AccountState(
      session: values[0] as RemoteSession?,
      syncConsent: values[1]! as bool,
    );
  }

  Future<void> login({required String email, required String password}) async {
    final current = state.asData?.value;
    if (current == null || current.isSubmitting) {
      return;
    }
    state = AsyncData<AccountState>(
      current.copyWith(
        isSubmitting: true,
        clearFailure: true,
        notice: AccountNotice.none,
      ),
    );
    try {
      final session = await ref
          .read(authGatewayProvider)
          .login(email: email.trim(), password: password);
      await ref.read(remoteSessionStoreProvider).save(session);
      state = AsyncData<AccountState>(
        current.copyWith(
          session: session,
          isSubmitting: false,
          clearFailure: true,
          notice: AccountNotice.signedIn,
        ),
      );
    } on AuthenticationFailure catch (error) {
      state = AsyncData<AccountState>(
        current.copyWith(
          isSubmitting: false,
          failure: _mapFailure(error.kind),
          notice: AccountNotice.none,
        ),
      );
    } on Object {
      state = AsyncData<AccountState>(
        current.copyWith(
          isSubmitting: false,
          failure: _unexpectedFailure,
          notice: AccountNotice.none,
        ),
      );
    }
  }

  Future<void> signOut() async {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }
    await ref.read(remoteSessionStoreProvider).clear();
    try {
      await ref.read(syncPreferencesRepositoryProvider).writeConsent(false);
      await ref.read(metadataSyncQueueProvider).clear();
      state = AsyncData<AccountState>(
        current.copyWith(
          clearSession: true,
          syncConsent: false,
          isSubmitting: false,
          clearFailure: true,
          notice: AccountNotice.signedOut,
        ),
      );
    } on Object {
      state = AsyncData<AccountState>(
        current.copyWith(
          clearSession: true,
          syncConsent: false,
          isSubmitting: false,
          failure: const OperationalFailure(
            kind: OperationalFailureKind.preferencesUnavailable,
            impact: OperationalFailureImpact.degraded,
            primaryAction: OperationalRecoveryAction.retry,
          ),
          notice: AccountNotice.signedOut,
        ),
      );
    }
  }

  Future<void> setSyncConsent(bool enabled) async {
    final current = state.asData?.value;
    if (current == null || (enabled && !current.isSignedIn)) {
      return;
    }
    try {
      await ref.read(syncPreferencesRepositoryProvider).writeConsent(enabled);
      if (!enabled) {
        await ref.read(metadataSyncQueueProvider).clear();
      }
      state = AsyncData<AccountState>(
        current.copyWith(
          syncConsent: enabled,
          clearFailure: true,
          notice: enabled
              ? AccountNotice.consentEnabled
              : AccountNotice.consentRevoked,
        ),
      );
    } on Object {
      state = AsyncData<AccountState>(
        current.copyWith(
          failure: const OperationalFailure(
            kind: OperationalFailureKind.preferencesUnavailable,
            impact: OperationalFailureImpact.degraded,
            primaryAction: OperationalRecoveryAction.retry,
          ),
          notice: AccountNotice.none,
        ),
      );
    }
  }

  void clearMessage() {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }
    state = AsyncData<AccountState>(
      current.copyWith(clearFailure: true, notice: AccountNotice.none),
    );
  }

  void _onSessionChanged(RemoteSessionChange change) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }
    final expired = change.reason == RemoteSessionChangeReason.expired;
    state = AsyncData<AccountState>(
      current.copyWith(
        session: change.session,
        clearSession: change.session == null,
        isSubmitting: false,
        failure: expired ? _expiredFailure : null,
        clearFailure: !expired,
        notice: change.reason == RemoteSessionChangeReason.signedOut
            ? AccountNotice.signedOut
            : AccountNotice.none,
      ),
    );
  }
}

final AsyncNotifierProvider<AccountController, AccountState>
accountControllerProvider =
    AsyncNotifierProvider<AccountController, AccountState>(
      AccountController.new,
    );

OperationalFailure _mapFailure(AuthenticationFailureKind kind) =>
    switch (kind) {
      AuthenticationFailureKind.invalidCredentials => const OperationalFailure(
        kind: OperationalFailureKind.invalidCredentials,
        impact: OperationalFailureImpact.degraded,
        primaryAction: OperationalRecoveryAction.retry,
        secondaryAction: OperationalRecoveryAction.continueOffline,
      ),
      AuthenticationFailureKind.networkUnavailable => const OperationalFailure(
        kind: OperationalFailureKind.networkUnavailable,
        impact: OperationalFailureImpact.degraded,
        primaryAction: OperationalRecoveryAction.retry,
        secondaryAction: OperationalRecoveryAction.continueOffline,
      ),
      AuthenticationFailureKind.serviceUnavailable ||
      AuthenticationFailureKind.invalidResponse => _unexpectedFailure,
    };

const OperationalFailure _expiredFailure = OperationalFailure(
  kind: OperationalFailureKind.sessionExpired,
  impact: OperationalFailureImpact.degraded,
  primaryAction: OperationalRecoveryAction.retry,
  secondaryAction: OperationalRecoveryAction.continueOffline,
);

const OperationalFailure _unexpectedFailure = OperationalFailure(
  kind: OperationalFailureKind.unexpected,
  impact: OperationalFailureImpact.degraded,
  primaryAction: OperationalRecoveryAction.retry,
  secondaryAction: OperationalRecoveryAction.continueOffline,
);
