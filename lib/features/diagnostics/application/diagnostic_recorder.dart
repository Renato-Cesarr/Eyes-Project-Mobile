import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;

import 'package:eyes_mobile/features/assistive_feedback/application/assistive_alert_observer.dart';
import 'package:eyes_mobile/features/assistive_feedback/domain/assistive_alert_message.dart';
import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_models.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_scan_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final diagnosticRecorderProvider = Provider((ref) => DiagnosticRecorder());
final diagnosticsEnabledProvider = Provider((ref) => false);

/// Local support telemetry, never scientific calibration or a media recorder.
final class DiagnosticRecorder implements AssistiveAlertObserver {
  DiagnosticRecorder({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const maximumEvents = 100;
  static const maximumSamples = 512;
  final DateTime Function() _clock;
  bool active = false;
  DateTime? _started;
  DateTime? _ended;
  int _frames = 0;
  int _alerts = 0;
  int _speechStarts = 0;
  int _problems = 0;
  int _omittedEvents = 0;
  final Map<String, int> _classes = {};
  final ListQueue<Map<String, Object?>> _events = ListQueue();
  final ListQueue<(String, DateTime)> _pending = ListQueue();
  final ListQueue<int> _preprocessing = ListQueue();
  final ListQueue<int> _inference = ListQueue();
  final ListQueue<int> _total = ListQueue();
  final ListQueue<int> _speech = ListQueue();

  void start() {
    clear();
    active = true;
    _started = _clock().toUtc();
    _event('started');
  }

  void stop() {
    if (!active) return;
    _event('stopped');
    _ended = _clock().toUtc();
    active = false;
    _pending.clear();
  }

  void clear() {
    active = false;
    _started = null;
    _ended = null;
    _frames = _alerts = _speechStarts = _problems = _omittedEvents = 0;
    _classes.clear();
    for (final queue in [
      _events,
      _pending,
      _preprocessing,
      _inference,
      _total,
      _speech,
    ]) {
      queue.clear();
    }
  }

  void recordFrame(DetectionBatch batch) {
    if (!active) return;
    _frames++;
    for (final kind in batch.detections.map((d) => d.kind).toSet()) {
      _classes.update(kind.name, (n) => n + 1, ifAbsent: () => 1);
    }
    _sample(_preprocessing, batch.timings.preprocessing.inMicroseconds);
    _sample(_inference, batch.timings.inference.inMicroseconds);
    _sample(_total, batch.timings.total.inMicroseconds);
  }

  void recordStatus(CameraScanStatus status) {
    if (active) _event('camera', {'state': status.name});
  }

  void recordProblem() {
    if (!active) return;
    _problems++;
    _event('application_problem');
  }

  @override
  void onAlertQueued(ProximityAlertEvent event, AssistiveAlertMessage message) {
    if (!active) return;
    _alerts++;
    _pending.add((message.text, event.occurredAt));
    if (_pending.length > 16) _pending.removeFirst();
    _event('alert_queued', {
      'kind': event.kind.name,
      'band': event.band.name,
      'direction': event.direction.name,
    });
  }

  void recordSpeechStarted(String message, DateTime startedAt) {
    if (!active) return;
    final index = _pending.toList().indexWhere((p) => p.$1 == message);
    if (index < 0) return;
    final pending = _pending.elementAt(index);
    _pending.remove(pending);
    _speechStarts++;
    _sample(_speech, startedAt.difference(pending.$2).inMicroseconds);
    _event('speech_started');
  }

  void _event(String name, [Map<String, Object?> fields = const {}]) {
    _events.add({
      'event': name,
      'elapsed_ms': _started == null
          ? 0
          : math.max(0, _clock().toUtc().difference(_started!).inMilliseconds),
      ...fields,
    });
    if (_events.length > maximumEvents) {
      _events.removeFirst();
      _omittedEvents++;
    }
  }

  void _sample(ListQueue<int> samples, int value) {
    if (value < 0) return;
    samples.add(value);
    if (samples.length > maximumSamples) samples.removeFirst();
  }

  Map<String, Object?> _summary(ListQueue<int> values) {
    final sorted = values.toList()..sort();
    if (sorted.isEmpty) return {'samples': 0};
    return {
      'samples': sorted.length,
      'mean_ms': sorted.reduce((a, b) => a + b) / sorted.length / 1000,
      'p50_ms': sorted[(sorted.length * .5).ceil() - 1] / 1000,
      'p95_ms': sorted[(sorted.length * .95).ceil() - 1] / 1000,
    };
  }

  String report() => jsonEncode({
    'schema_version': 1,
    'purpose': 'local_support_diagnostic_not_scientific_evaluation',
    'build_commit': const String.fromEnvironment(
      'EYES_BUILD_COMMIT',
      defaultValue: 'unidentified',
    ),
    'model': 'efficientdet-lite0.tflite',
    'started_at': _started?.toIso8601String(),
    'updated_at': _clock().toUtc().toIso8601String(),
    'ended_at': _ended?.toIso8601String(),
    'status': active ? 'recording_snapshot' : 'stopped',
    'frames_processed': _frames,
    'frames_containing_class': _classes,
    'alerts_queued': _alerts,
    'matched_speech_starts': _speechStarts,
    'application_problems': _problems,
    'timings_last_up_to_512_samples': {
      'preprocessing': _summary(_preprocessing),
      'inference': _summary(_inference),
      'vision_total': _summary(_total),
      'source_to_matched_tts_callback': _summary(_speech),
    },
    'events': _events.toList(),
    'older_events_omitted': _omittedEvents,
    'limits': {'events': maximumEvents, 'samples_per_timing': maximumSamples},
    'limitations': [
      'no_ground_truth_or_accuracy',
      'not_calibration',
      'no_fps_memory_temperature_or_battery_measurement',
      'tts_callback_is_not_acoustic_measurement',
      'process_kill_may_lose_last_5_seconds',
      'timestamps_use_device_clock',
    ],
    'privacy': {
      'media_collected': false,
      'account_required': false,
      'automatic_upload': false,
    },
  });
}
