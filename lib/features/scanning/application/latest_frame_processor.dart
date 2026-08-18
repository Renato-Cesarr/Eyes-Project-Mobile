import 'dart:async';

typedef FrameClock = DateTime Function();
typedef FrameDelay = Future<void> Function(Duration duration);

final class FrameProcessorSnapshot {
  const FrameProcessorSnapshot({
    required this.received,
    required this.processed,
    required this.dropped,
    required this.lastProcessingTime,
  });

  final int received;
  final int processed;
  final int dropped;
  final Duration lastProcessingTime;
}

/// Applies backpressure without building an unbounded frame queue.
///
/// At most one frame is processed and one newer frame is retained. When more
/// frames arrive, the retained frame is replaced so the consumer receives the
/// freshest available image instead of stale camera data.
final class LatestFrameProcessor<T> {
  LatestFrameProcessor({
    required this.onFrame,
    required this.minimumInterval,
    FrameClock? clock,
    FrameDelay? delay,
  }) : _clock = clock ?? DateTime.now,
       _delay = delay ?? Future<void>.delayed;

  final Future<void> Function(T frame) onFrame;
  final Duration minimumInterval;
  final FrameClock _clock;
  final FrameDelay _delay;

  T? _pending;
  bool _isRunning = false;
  bool _isClosed = false;
  DateTime? _lastStartedAt;
  Completer<void>? _idleCompleter;
  int _received = 0;
  int _processed = 0;
  int _dropped = 0;
  Duration _lastProcessingTime = Duration.zero;

  FrameProcessorSnapshot get snapshot => FrameProcessorSnapshot(
    received: _received,
    processed: _processed,
    dropped: _dropped,
    lastProcessingTime: _lastProcessingTime,
  );

  void add(T frame) {
    if (_isClosed) {
      return;
    }
    _received++;
    if (_isRunning) {
      if (_pending != null) {
        _dropped++;
      }
      _pending = frame;
      return;
    }

    _isRunning = true;
    _idleCompleter = Completer<void>();
    unawaited(_drain(frame));
  }

  Future<void> close() async {
    _isClosed = true;
    if (_pending != null) {
      _pending = null;
      _dropped++;
    }
    await (_idleCompleter?.future ?? Future<void>.value());
  }

  Future<void> _drain(T firstFrame) async {
    var current = firstFrame;
    try {
      while (!_isClosed) {
        final previousStart = _lastStartedAt;
        if (previousStart != null) {
          final elapsed = _clock().difference(previousStart);
          final remaining = minimumInterval - elapsed;
          if (remaining > Duration.zero) {
            await _delay(remaining);
          }
        }
        if (_isClosed) {
          break;
        }

        final newest = _pending;
        if (newest != null) {
          _pending = null;
          _dropped++;
          current = newest;
        }

        final startedAt = _clock();
        _lastStartedAt = startedAt;
        await onFrame(current);
        _lastProcessingTime = _clock().difference(startedAt);
        _processed++;

        final next = _pending;
        if (next == null) {
          break;
        }
        _pending = null;
        current = next;
      }
    } finally {
      if (_isClosed && _pending != null) {
        _pending = null;
        _dropped++;
      }
      _isRunning = false;
      final idleCompleter = _idleCompleter;
      _idleCompleter = null;
      if (idleCompleter != null && !idleCompleter.isCompleted) {
        idleCompleter.complete();
      }
    }
  }
}
