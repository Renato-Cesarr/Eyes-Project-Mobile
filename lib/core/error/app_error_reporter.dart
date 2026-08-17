import 'package:eyes_mobile/core/logging/secure_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class AppErrorReporter {
  const AppErrorReporter(this._logger);

  final SecureLogger _logger;

  void capture(Object error, StackTrace stackTrace, {required String source}) {
    _logger.severe(
      'unhandled-error',
      context: <String, Object?>{
        'errorType': error.runtimeType.toString(),
        'source': source,
      },
      stackTrace: stackTrace,
    );
  }

  void captureFlutterError(FlutterErrorDetails details) {
    capture(
      details.exception,
      details.stack ?? StackTrace.current,
      source: details.library ?? 'flutter-framework',
    );
  }
}

final Provider<AppErrorReporter> appErrorReporterProvider =
    Provider<AppErrorReporter>(
      (Ref ref) => throw StateError(
        'AppErrorReporter must be overridden during bootstrap.',
      ),
    );
