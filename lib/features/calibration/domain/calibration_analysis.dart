final class CalibrationAnalysis {
  CalibrationAnalysis._({
    required this.frameCount,
    required this.alertCount,
    required this.matchedSpeechCount,
    required this.confusionMatrix,
    required this.cameraToDecisionMicroseconds,
    required this.preprocessingMicroseconds,
    required this.inferenceMicroseconds,
    required this.visionTotalMicroseconds,
    required this.cameraToSpeechStartMicroseconds,
    required this.hazardFrameCount,
    required this.missedHazardFrameCount,
    required this.distantFrameCount,
    required this.falseAlertFrameCount,
    required this.repeatedAlertCount,
    required this.timeToFirstAlertMicroseconds,
    required this.sessionToFirstAlertMicroseconds,
    required this.cameraToQueueMicroseconds,
    required this.queueToSpeechMicroseconds,
  });

  factory CalibrationAnalysis.fromEvents(
    Iterable<Map<String, Object?>> events,
  ) {
    final frames = events
        .where((event) => event['type'] == 'frame_evaluated')
        .toList(growable: false);
    final alerts = events
        .where((event) => event['type'] == 'alert_queued')
        .toList(growable: false);
    final speechStarts = events
        .where(
          (event) =>
              event['type'] == 'speech_started' &&
              event['matched_alert'] == true,
        )
        .toList(growable: false);
    final sessions = events
        .where((event) => event['type'] == 'session_started')
        .toList(growable: false);

    final confusion = <String, Map<String, int>>{};
    var hazardFrames = 0;
    var missedHazardFrames = 0;
    var distantFrames = 0;
    var falseAlertFrames = 0;
    for (final frame in frames) {
      final expected = _requiredString(frame, 'expected_band');
      final predicted = _requiredString(frame, 'predicted_band');
      final row = confusion.putIfAbsent(expected, () => <String, int>{});
      row[predicted] = (row[predicted] ?? 0) + 1;
      if (expected == 'attention' || expected == 'veryNear') {
        hazardFrames++;
        if (predicted == 'distant' || predicted == 'missed') {
          missedHazardFrames++;
        }
      }
      if (expected == 'distant') {
        distantFrames++;
        if (frame['announced'] == true) {
          falseAlertFrames++;
        }
      }
    }

    return CalibrationAnalysis._(
      frameCount: frames.length,
      alertCount: alerts.length,
      matchedSpeechCount: speechStarts.length,
      confusionMatrix: _freezeMatrix(confusion),
      cameraToDecisionMicroseconds: _integerMetric(
        frames,
        'camera_to_decision_us',
      ),
      preprocessingMicroseconds: _integerMetric(frames, 'preprocessing_us'),
      inferenceMicroseconds: _integerMetric(frames, 'inference_us'),
      visionTotalMicroseconds: _integerMetric(frames, 'vision_total_us'),
      cameraToSpeechStartMicroseconds: _integerMetric(
        speechStarts,
        'camera_to_speech_start_us',
      ),
      hazardFrameCount: hazardFrames,
      missedHazardFrameCount: missedHazardFrames,
      distantFrameCount: distantFrames,
      falseAlertFrameCount: falseAlertFrames,
      repeatedAlertCount: _repeatedAlerts(alerts),
      timeToFirstAlertMicroseconds: _timeToFirstFrameAlert(frames, alerts),
      sessionToFirstAlertMicroseconds: _timeToFirstAlert(sessions, alerts),
      cameraToQueueMicroseconds: _timestampDeltas(
        alerts,
        'source_at',
        'emitted_at',
      ),
      queueToSpeechMicroseconds: _queueToSpeech(alerts, speechStarts),
    );
  }

  final int frameCount;
  final int alertCount;
  final int matchedSpeechCount;
  final Map<String, Map<String, int>> confusionMatrix;
  final List<int> cameraToDecisionMicroseconds;
  final List<int> preprocessingMicroseconds;
  final List<int> inferenceMicroseconds;
  final List<int> visionTotalMicroseconds;
  final List<int> cameraToSpeechStartMicroseconds;
  final int hazardFrameCount;
  final int missedHazardFrameCount;
  final int distantFrameCount;
  final int falseAlertFrameCount;
  final int repeatedAlertCount;
  final List<int> timeToFirstAlertMicroseconds;
  final List<int> sessionToFirstAlertMicroseconds;
  final List<int> cameraToQueueMicroseconds;
  final List<int> queueToSpeechMicroseconds;

  double? percentile(List<int> values, double percentile) {
    if (values.isEmpty) {
      return null;
    }
    if (!percentile.isFinite || percentile < 0 || percentile > 100) {
      throw RangeError.range(percentile, 0, 100, 'percentile');
    }
    final sorted = List<int>.of(values)..sort();
    final rank = (percentile / 100) * (sorted.length - 1);
    final lower = rank.floor();
    final upper = rank.ceil();
    if (lower == upper) {
      return sorted[lower].toDouble();
    }
    final fraction = rank - lower;
    return sorted[lower] + (sorted[upper] - sorted[lower]) * fraction;
  }

  double? get missedHazardRate =>
      hazardFrameCount == 0 ? null : missedHazardFrameCount / hazardFrameCount;

  double? get falseAlertRate =>
      distantFrameCount == 0 ? null : falseAlertFrameCount / distantFrameCount;

  Duration? get firstAlertLatency {
    final value = percentile(timeToFirstAlertMicroseconds, 50);
    return value == null ? null : Duration(microseconds: value.round());
  }

  Map<String, Object?> toJson() => {
    'frameCount': frameCount,
    'alertCount': alertCount,
    'matchedSpeechCount': matchedSpeechCount,
    'confusionMatrix': confusionMatrix,
    'latencyMs': {
      'cameraToDecisionP50': _milliseconds(
        percentile(cameraToDecisionMicroseconds, 50),
      ),
      'cameraToDecisionP95': _milliseconds(
        percentile(cameraToDecisionMicroseconds, 95),
      ),
      'preprocessingP50': _milliseconds(
        percentile(preprocessingMicroseconds, 50),
      ),
      'inferenceP50': _milliseconds(percentile(inferenceMicroseconds, 50)),
      'visionTotalP50': _milliseconds(percentile(visionTotalMicroseconds, 50)),
      'cameraToSpeechStartP50': _milliseconds(
        percentile(cameraToSpeechStartMicroseconds, 50),
      ),
      'cameraToSpeechStartP95': _milliseconds(
        percentile(cameraToSpeechStartMicroseconds, 95),
      ),
      'firstAlertP50': _milliseconds(
        percentile(timeToFirstAlertMicroseconds, 50),
      ),
      'firstAlertP95': _milliseconds(
        percentile(timeToFirstAlertMicroseconds, 95),
      ),
    },
    'missedHazardRate': missedHazardRate,
    'falseAlertRate': falseAlertRate,
    'repeatedAlertCount': repeatedAlertCount,
    'sampleCounts': {
      'hazardFrames': hazardFrameCount,
      'missedHazardFrames': missedHazardFrameCount,
      'distantFrames': distantFrameCount,
      'falseAlertFrames': falseAlertFrameCount,
    },
    'latencyStatistics': {
      for (final entry in <String, List<int>>{
        'preprocessing': preprocessingMicroseconds,
        'inference': inferenceMicroseconds,
        'visionTotal': visionTotalMicroseconds,
        'cameraToDecision': cameraToDecisionMicroseconds,
        'cameraToQueue': cameraToQueueMicroseconds,
        'queueToSpeech': queueToSpeechMicroseconds,
        'cameraToSpeechStart': cameraToSpeechStartMicroseconds,
        'firstOperationalAlert': timeToFirstAlertMicroseconds,
        'sessionToFirstAlert': sessionToFirstAlertMicroseconds,
      }.entries)
        entry.key: {
          'n': entry.value.length,
          'p50Ms': _milliseconds(percentile(entry.value, 50)),
          'p95Ms': _milliseconds(percentile(entry.value, 95)),
          'unit': 'ms',
          'method': 'linear_interpolation',
        },
    },
  };
}

List<int> _timeToFirstFrameAlert(
  List<Map<String, Object?>> frames,
  List<Map<String, Object?>> alerts,
) {
  final origins = <String, DateTime>{};
  for (final frame in frames) {
    if (frame['captured_at'] is! String) continue;
    final id = _requiredString(frame, 'session_id');
    final time = _eventTime(frame, preferredKey: 'captured_at');
    if (origins[id] == null || time.isBefore(origins[id]!)) origins[id] = time;
  }
  return _timeToFirstAlert([
    for (final entry in origins.entries)
      {'session_id': entry.key, 'emitted_at': entry.value.toIso8601String()},
  ], alerts);
}

List<int> _timestampDeltas(
  List<Map<String, Object?>> events,
  String startKey,
  String endKey,
) => [
  for (final event in events)
    if (event[startKey] is String &&
        event[endKey] is String &&
        !_eventTime(
          event,
          preferredKey: endKey,
        ).isBefore(_eventTime(event, preferredKey: startKey)))
      _eventTime(
        event,
        preferredKey: endKey,
      ).difference(_eventTime(event, preferredKey: startKey)).inMicroseconds,
];

List<int> _queueToSpeech(
  List<Map<String, Object?>> alerts,
  List<Map<String, Object?>> speeches,
) {
  final byId = <String, Map<String, Object?>>{
    for (final alert in alerts)
      if (alert['correlation_id'] is String)
        '${alert['session_id']}:${alert['correlation_id']}': alert,
  };
  final values = <int>[];
  for (final speech in speeches) {
    final alert = byId['${speech['session_id']}:${speech['correlation_id']}'];
    if (alert == null || speech['started_at'] is! String) continue;
    final delta = _eventTime(
      speech,
      preferredKey: 'started_at',
    ).difference(_eventTime(alert));
    if (!delta.isNegative) values.add(delta.inMicroseconds);
  }
  return values;
}

List<int> _integerMetric(Iterable<Map<String, Object?>> events, String key) =>
    events
        .map((event) => event[key])
        .whereType<num>()
        .map((value) => value.round())
        .toList(growable: false);

String _requiredString(Map<String, Object?> event, String key) {
  final value = event[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Evento de calibração sem $key válido.');
  }
  return value;
}

Map<String, Map<String, int>> _freezeMatrix(
  Map<String, Map<String, int>> source,
) => Map<String, Map<String, int>>.unmodifiable(
  source.map(
    (key, value) => MapEntry(key, Map<String, int>.unmodifiable(value)),
  ),
);

int _repeatedAlerts(List<Map<String, Object?>> alerts) {
  final ordered = List<Map<String, Object?>>.of(alerts)
    ..sort((a, b) => _eventTime(a).compareTo(_eventTime(b)));
  final lastBySignature = <String, DateTime>{};
  var repeated = 0;
  for (final alert in ordered) {
    final signature = [
      alert['session_id'],
      alert['kind'],
      alert['band'],
      alert['direction'],
    ].join(':');
    final occurredAt = _eventTime(alert, preferredKey: 'source_at');
    final previous = lastBySignature[signature];
    if (previous != null &&
        occurredAt.difference(previous) < const Duration(seconds: 6)) {
      repeated++;
    }
    lastBySignature[signature] = occurredAt;
  }
  return repeated;
}

List<int> _timeToFirstAlert(
  List<Map<String, Object?>> sessions,
  List<Map<String, Object?>> alerts,
) {
  final startsBySession = <String, DateTime>{};
  for (final session in sessions) {
    final sessionId = _requiredString(session, 'session_id');
    final timestamp = _eventTime(session);
    final current = startsBySession[sessionId];
    if (current == null || timestamp.isBefore(current)) {
      startsBySession[sessionId] = timestamp;
    }
  }
  final firstAlertsBySession = <String, DateTime>{};
  for (final alert in alerts) {
    final sessionId = _requiredString(alert, 'session_id');
    final timestamp = _eventTime(alert);
    final current = firstAlertsBySession[sessionId];
    if (current == null || timestamp.isBefore(current)) {
      firstAlertsBySession[sessionId] = timestamp;
    }
  }
  return startsBySession.entries
      .map((entry) {
        final firstAlert = firstAlertsBySession[entry.key];
        if (firstAlert == null) {
          return null;
        }
        final latency = firstAlert.difference(entry.value);
        return latency.isNegative ? null : latency.inMicroseconds;
      })
      .whereType<int>()
      .toList(growable: false);
}

DateTime _eventTime(
  Map<String, Object?> event, {
  String preferredKey = 'emitted_at',
}) {
  final raw = event[preferredKey] ?? event['emitted_at'];
  if (raw is! String) {
    throw FormatException('Evento de calibração sem timestamp.');
  }
  return DateTime.parse(raw).toUtc();
}

double? _milliseconds(double? microseconds) =>
    microseconds == null ? null : microseconds / 1000;
