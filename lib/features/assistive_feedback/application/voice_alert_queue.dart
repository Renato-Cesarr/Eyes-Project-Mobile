import 'dart:async';

import 'package:eyes_mobile/features/assistive_feedback/application/speech_gateway.dart';
import 'package:eyes_mobile/features/assistive_feedback/domain/assistive_alert_message.dart';

typedef Clock = DateTime Function();
typedef VoiceQueueFailureHandler =
    void Function(Object error, StackTrace stackTrace);

final class VoiceAlertQueue {
  VoiceAlertQueue(
    this._gateway, {
    Clock? clock,
    this.onFailure,
    this.deduplicationCooldown = const Duration(seconds: 4),
    this.maximumPending = 4,
  }) : _clock = clock ?? DateTime.now;

  final SpeechGateway _gateway;
  final Clock _clock;
  final VoiceQueueFailureHandler? onFailure;
  final Duration deduplicationCooldown;
  final int maximumPending;
  final List<AssistiveAlertMessage> _pending = [];
  final Map<String, DateTime> _lastDelivered = {};

  AssistiveAlertMessage? _current;
  bool _draining = false;
  bool _disposed = false;
  Completer<void>? _idleCompleter;

  int get pendingCount => _pending.length;
  AssistiveAlertMessage? get current => _current;
  Future<void> get idle => _idleCompleter?.future ?? Future<void>.value();

  void enqueue(AssistiveAlertMessage message) {
    if (_disposed || _isDuplicate(message)) {
      return;
    }
    final current = _current;
    if (current?.deduplicationKey == message.deduplicationKey ||
        _pending.any(
          (item) => item.deduplicationKey == message.deduplicationKey,
        )) {
      return;
    }

    _pending.add(message);
    _pending.sort((a, b) => b.priority.compareTo(a.priority));
    if (_pending.length > maximumPending) {
      _pending.removeLast();
    }
    _idleCompleter ??= Completer<void>();

    if (message.isCritical && current != null && !current.isCritical) {
      unawaited(_gateway.stop());
    }
    unawaited(_drain());
  }

  Future<void> clear() async {
    _pending.clear();
    _current = null;
    await _gateway.stop();
    _completeIdle();
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await clear();
    await _gateway.dispose();
  }

  bool _isDuplicate(AssistiveAlertMessage message) {
    final deliveredAt = _lastDelivered[message.deduplicationKey];
    return deliveredAt != null &&
        _clock().difference(deliveredAt) < deduplicationCooldown;
  }

  Future<void> _drain() async {
    if (_draining || _disposed) {
      return;
    }
    _draining = true;
    try {
      while (_pending.isNotEmpty && !_disposed) {
        final next = _pending.removeAt(0);
        _current = next;
        try {
          await _gateway.speak(next.text);
          _lastDelivered[next.deduplicationKey] = _clock();
        } on Object catch (error, stackTrace) {
          onFailure?.call(error, stackTrace);
        } finally {
          _current = null;
        }
      }
    } finally {
      _draining = false;
      if (_pending.isEmpty) {
        _completeIdle();
      } else if (!_disposed) {
        unawaited(_drain());
      }
    }
  }

  void _completeIdle() {
    final completer = _idleCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _idleCompleter = null;
  }
}
