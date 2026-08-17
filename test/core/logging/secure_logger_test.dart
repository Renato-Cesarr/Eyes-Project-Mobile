import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:eyes_mobile/core/logging/secure_logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

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

  test('publishes sanitized records at every supported level', () async {
    final logger = SecureLogger(AppEnvironment.dev())..initialize();
    final records = <LogRecord>[];
    final subscription = Logger.root.onRecord.listen(records.add);

    logger
      ..initialize()
      ..debug('debug-event', context: const <String, Object?>{'token': 'x'})
      ..info('info-event')
      ..warning('warning-event')
      ..severe('severe-event', stackTrace: StackTrace.current);
    await Future<void>.delayed(Duration.zero);

    expect(records, hasLength(4));
    expect(records.first.message, contains('[REDACTED]'));
    expect(records.map((record) => record.level), <Level>[
      Level.FINE,
      Level.INFO,
      Level.WARNING,
      Level.SEVERE,
    ]);

    await subscription.cancel();
    await logger.dispose();
  });

  test('production logger ignores verbose records', () async {
    final logger = SecureLogger(AppEnvironment.prod())..initialize();
    final records = <LogRecord>[];
    final subscription = Logger.root.onRecord.listen(records.add);

    logger
      ..debug('ignored-debug')
      ..warning('visible-warning');
    await Future<void>.delayed(Duration.zero);

    expect(records.map((record) => record.message), <Object>[
      'visible-warning',
    ]);

    await subscription.cancel();
    await logger.dispose();
    await SecureLogger(AppEnvironment.dev()).dispose();
  });
}
