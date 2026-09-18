import 'dart:async';

import 'package:eyes_mobile/core/session/remote_session.dart';
import 'package:eyes_mobile/core/session/remote_session_store.dart';
import 'package:eyes_mobile/features/account/application/auth_gateway.dart';
import 'package:eyes_mobile/features/account/application/metadata_sync_queue.dart';
import 'package:eyes_mobile/features/account/application/sync_preferences_repository.dart';
import 'package:eyes_mobile/features/account/domain/sync_metadata_record.dart';

const RemoteSession testRemoteSession = RemoteSession(
  accessToken: 'test-access-token',
  user: RemoteUser(
    id: '6db3192c-b7c3-4d93-8d5d-1ba8ad093b09',
    name: 'Pessoa Teste',
    email: 'pessoa@example.com',
  ),
);

final class InMemoryRemoteSessionStore implements RemoteSessionStore {
  InMemoryRemoteSessionStore({this.session});

  RemoteSession? session;
  final StreamController<RemoteSessionChange> _changes =
      StreamController<RemoteSessionChange>.broadcast();

  @override
  Stream<RemoteSessionChange> get changes => _changes.stream;

  @override
  Future<void> clear({
    RemoteSessionChangeReason reason = RemoteSessionChangeReason.signedOut,
  }) async {
    session = null;
    _changes.add(RemoteSessionChange(session: null, reason: reason));
  }

  @override
  Future<RemoteSession?> read() async => session;

  @override
  Future<void> save(RemoteSession value) async {
    session = value;
    _changes.add(
      RemoteSessionChange(
        session: value,
        reason: RemoteSessionChangeReason.signedIn,
      ),
    );
  }

  Future<void> expire() => clear(reason: RemoteSessionChangeReason.expired);

  Future<void> dispose() => _changes.close();
}

final class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({this.result = testRemoteSession, this.failure});

  final RemoteSession result;
  final AuthenticationFailure? failure;
  int calls = 0;
  String? lastEmail;
  String? lastPassword;

  @override
  Future<RemoteSession> login({
    required String email,
    required String password,
  }) async {
    calls++;
    lastEmail = email;
    lastPassword = password;
    if (failure case final failure?) {
      throw failure;
    }
    return result;
  }
}

final class InMemorySyncPreferencesRepository
    implements SyncPreferencesRepository {
  InMemorySyncPreferencesRepository({this.consent = false});

  bool consent;
  int writes = 0;

  @override
  Future<bool> readConsent() async => consent;

  @override
  Future<void> writeConsent(bool value) async {
    consent = value;
    writes++;
  }
}

final class InMemoryMetadataSyncQueue implements MetadataSyncQueue {
  final List<SyncMetadataRecord> records = <SyncMetadataRecord>[];
  int clearCalls = 0;

  @override
  Future<void> clear() async {
    clearCalls++;
    records.clear();
  }

  @override
  Future<bool> enqueue(SyncMetadataRecord record) async {
    if (records.any((item) => item.idempotencyKey == record.idempotencyKey)) {
      return false;
    }
    records.add(record);
    return true;
  }

  @override
  Future<List<SyncMetadataRecord>> readPending() async =>
      List<SyncMetadataRecord>.unmodifiable(records);

  @override
  Future<void> remove(String idempotencyKey) async {
    records.removeWhere((item) => item.idempotencyKey == idempotencyKey);
  }
}
