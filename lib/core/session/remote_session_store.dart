import 'package:eyes_mobile/core/session/remote_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RemoteSessionChangeReason { signedIn, signedOut, expired }

final class RemoteSessionChange {
  const RemoteSessionChange({required this.session, required this.reason});

  final RemoteSession? session;
  final RemoteSessionChangeReason reason;
}

abstract interface class RemoteSessionStore {
  Stream<RemoteSessionChange> get changes;

  Future<RemoteSession?> read();

  Future<void> save(RemoteSession session);

  Future<void> clear({
    RemoteSessionChangeReason reason = RemoteSessionChangeReason.signedOut,
  });
}

final Provider<RemoteSessionStore> remoteSessionStoreProvider =
    Provider<RemoteSessionStore>((Ref ref) {
      throw StateError('RemoteSessionStore must be configured at bootstrap.');
    });
