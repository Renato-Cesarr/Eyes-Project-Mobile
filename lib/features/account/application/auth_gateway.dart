import 'package:eyes_mobile/core/session/remote_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthenticationFailureKind {
  invalidCredentials,
  networkUnavailable,
  serviceUnavailable,
  invalidResponse,
}

final class AuthenticationFailure implements Exception {
  const AuthenticationFailure(this.kind);

  final AuthenticationFailureKind kind;
}

abstract interface class AuthGateway {
  Future<RemoteSession> login({
    required String email,
    required String password,
  });
}

final Provider<AuthGateway> authGatewayProvider = Provider<AuthGateway>((
  Ref ref,
) {
  throw StateError('AuthGateway must be configured at bootstrap.');
});
