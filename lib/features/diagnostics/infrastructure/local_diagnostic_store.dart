import 'dart:convert';

import 'package:eyes_mobile/features/diagnostics/application/diagnostic_ports.dart';
import 'package:flutter/services.dart';

final class LocalDiagnosticStore implements DiagnosticStore {
  LocalDiagnosticStore({MethodChannel? channel, DateTime Function()? clock})
    : _channel =
          channel ??
          const MethodChannel('br.com.eyesproject.mobile/diagnostics'),
      _clock = clock ?? DateTime.now;
  final MethodChannel _channel;
  final DateTime Function() _clock;
  static const maximumBytes = 100000;
  Future<void> _writes = Future.value();

  @override
  Future<String?> read() async {
    final text = await _channel.invokeMethod<String>('readReport');
    if (text == null) return null;
    try {
      final document = jsonDecode(text) as Map<String, dynamic>;
      final updated = DateTime.parse(document['updated_at'] as String);
      if (utf8.encode(text).length <= maximumBytes &&
          document['schema_version'] == 1 &&
          _clock().toUtc().difference(updated).inDays < 7 &&
          !updated.isAfter(_clock().toUtc().add(const Duration(minutes: 5)))) {
        return text;
      }
    } on Object {
      // Corrupt or expired support records must not block assistance.
    }
    await clear();
    return null;
  }

  @override
  Future<void> write(String report) {
    if (utf8.encode(report).length > maximumBytes) {
      return Future.error(StateError('diagnostic_too_large'));
    }
    return _enqueue(
      () => _channel.invokeMethod<void>('writeReport', {'report': report}),
    );
  }

  @override
  Future<void> clear() =>
      _enqueue(() => _channel.invokeMethod<void>('clearReport'));

  Future<void> _enqueue(Future<void> Function() action) {
    final next = _writes.then((_) => action());
    _writes = next.catchError((Object _) {});
    return next;
  }
}
