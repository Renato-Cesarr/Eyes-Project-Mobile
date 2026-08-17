import 'dart:async';

import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final class SecureLogger {
  SecureLogger(this._environment) : _logger = Logger('eyes-mobile');

  static const Set<String> _sensitiveKeys = <String>{
    'authorization',
    'cookie',
    'email',
    'password',
    'refreshToken',
    'token',
  };

  final AppEnvironment _environment;
  final Logger _logger;
  StreamSubscription<LogRecord>? _subscription;

  void initialize() {
    if (_subscription != null) {
      return;
    }

    Logger.root.level = _environment.enableVerboseLogs
        ? Level.ALL
        : Level.WARNING;
    _subscription = Logger.root.onRecord.listen((LogRecord record) {
      if (kDebugMode || record.level >= Level.SEVERE) {
        debugPrint(
          '[${record.level.name}] ${record.loggerName}: ${record.message}',
        );
      }
    });
  }

  Future<void> dispose() async => _subscription?.cancel();

  void debug(String event, {Map<String, Object?> context = const {}}) {
    _log(Level.FINE, event, context);
  }

  void info(String event, {Map<String, Object?> context = const {}}) {
    _log(Level.INFO, event, context);
  }

  void warning(String event, {Map<String, Object?> context = const {}}) {
    _log(Level.WARNING, event, context);
  }

  void severe(
    String event, {
    Map<String, Object?> context = const {},
    StackTrace? stackTrace,
  }) {
    _logger.log(Level.SEVERE, _format(event, context), null, stackTrace);
  }

  @visibleForTesting
  Map<String, Object?> sanitizeContext(Map<String, Object?> context) {
    return context.map((String key, Object? value) {
      final isSensitive = _sensitiveKeys.any(
        (String sensitiveKey) =>
            key.toLowerCase().contains(sensitiveKey.toLowerCase()),
      );
      return MapEntry<String, Object?>(key, isSensitive ? '[REDACTED]' : value);
    });
  }

  void _log(Level level, String event, Map<String, Object?> context) {
    _logger.log(level, _format(event, context));
  }

  String _format(String event, Map<String, Object?> context) {
    final safeContext = sanitizeContext(context);
    return safeContext.isEmpty ? event : '$event | $safeContext';
  }
}

final Provider<SecureLogger> secureLoggerProvider = Provider<SecureLogger>(
  (Ref ref) =>
      throw StateError('SecureLogger must be overridden during bootstrap.'),
);
