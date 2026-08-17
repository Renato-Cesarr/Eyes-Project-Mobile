import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:eyes_mobile/core/error/app_error_reporter.dart';
import 'package:eyes_mobile/core/logging/secure_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

void main() {
  test('reports Dart and Flutter errors without sensitive payloads', () async {
    final logger = SecureLogger(AppEnvironment.dev())..initialize();
    final reporter = AppErrorReporter(logger);
    final records = <LogRecord>[];
    final subscription = Logger.root.onRecord.listen(records.add);

    reporter.capture(
      StateError('private details'),
      StackTrace.current,
      source: 'unit-test',
    );
    reporter.captureFlutterError(
      FlutterErrorDetails(exception: ArgumentError('invalid')),
    );
    await Future<void>.delayed(Duration.zero);

    expect(records, hasLength(2));
    expect(records.first.message, contains('source: unit-test'));
    expect(records.first.message, isNot(contains('private details')));
    expect(records.last.message, contains('source: Flutter framework'));

    await subscription.cancel();
    await logger.dispose();
  });
}
