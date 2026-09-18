import 'dart:async';
import 'dart:convert';

import 'package:eyes_mobile/core/logging/secure_logger.dart';
import 'package:eyes_mobile/core/session/remote_session.dart';
import 'package:eyes_mobile/core/session/remote_session_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final class SecureRemoteSessionStore implements RemoteSessionStore {
  SecureRemoteSessionStore(this._storage, this._logger);

  static const String _sessionKey = 'eyes.remote-session.v1';

  final FlutterSecureStorage _storage;
  final SecureLogger _logger;
  final StreamController<RemoteSessionChange> _changes =
      StreamController<RemoteSessionChange>.broadcast();

  @override
  Stream<RemoteSessionChange> get changes => _changes.stream;

  @override
  Future<RemoteSession?> read() async {
    final encoded = await _storage.read(key: _sessionKey);
    if (encoded == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Session payload is not an object.');
      }
      return RemoteSession.fromJson(decoded);
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'remote-session-invalid',
        context: <String, Object?>{'errorType': error.runtimeType.toString()},
      );
      _logger.debug(
        'remote-session-invalid-stack',
        context: <String, Object?>{
          'stackType': stackTrace.runtimeType.toString(),
        },
      );
      await _storage.delete(key: _sessionKey);
      return null;
    }
  }

  @override
  Future<void> save(RemoteSession session) async {
    await _storage.write(key: _sessionKey, value: jsonEncode(session.toJson()));
    _changes.add(
      RemoteSessionChange(
        session: session,
        reason: RemoteSessionChangeReason.signedIn,
      ),
    );
  }

  @override
  Future<void> clear({
    RemoteSessionChangeReason reason = RemoteSessionChangeReason.signedOut,
  }) async {
    await _storage.delete(key: _sessionKey);
    _changes.add(RemoteSessionChange(session: null, reason: reason));
  }

  Future<void> dispose() => _changes.close();
}
