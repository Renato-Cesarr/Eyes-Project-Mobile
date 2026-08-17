import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:eyes_mobile/core/logging/secure_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('redacts sensitive values from structured logging context', () {
    final logger = SecureLogger(AppEnvironment.dev());

    final sanitized = logger.sanitizeContext(<String, Object?>{
      'email': 'person@example.com',
      'method': 'GET',
      'refreshToken': 'secret',
    });

    expect(sanitized['email'], '[REDACTED]');
    expect(sanitized['refreshToken'], '[REDACTED]');
    expect(sanitized['method'], 'GET');
  });
}
