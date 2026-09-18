import 'package:eyes_mobile/core/recovery/operational_failure.dart';
import 'package:eyes_mobile/core/session/remote_session.dart';

enum AccountNotice { none, signedIn, signedOut, consentEnabled, consentRevoked }

final class AccountState {
  const AccountState({
    this.session,
    this.syncConsent = false,
    this.isSubmitting = false,
    this.failure,
    this.notice = AccountNotice.none,
  });

  final RemoteSession? session;
  final bool syncConsent;
  final bool isSubmitting;
  final OperationalFailure? failure;
  final AccountNotice notice;

  bool get isSignedIn => session != null;

  AccountState copyWith({
    RemoteSession? session,
    bool clearSession = false,
    bool? syncConsent,
    bool? isSubmitting,
    OperationalFailure? failure,
    bool clearFailure = false,
    AccountNotice? notice,
  }) => AccountState(
    session: clearSession ? null : session ?? this.session,
    syncConsent: syncConsent ?? this.syncConsent,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    failure: clearFailure ? null : failure ?? this.failure,
    notice: notice ?? this.notice,
  );
}
