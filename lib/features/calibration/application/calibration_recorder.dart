import 'dart:collection';
import 'dart:math' as math;

import 'package:eyes_mobile/features/assistive_feedback/application/assistive_alert_observer.dart';
import 'package:eyes_mobile/features/assistive_feedback/domain/assistive_alert_message.dart';
import 'package:eyes_mobile/features/calibration/application/calibration_event_sink.dart';
import 'package:eyes_mobile/features/calibration/domain/calibration_configuration.dart';
import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_models.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_policy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef CalibrationClock = DateTime Function();

final Provider<CalibrationRecorder> calibrationRecorderProvider =
    Provider<CalibrationRecorder>((Ref ref) => CalibrationRecorder.disabled());

/// Emits privacy-safe JSON-compatible events for controlled TCC evaluation.
///
/// The recorder is inert unless a calibration build and a valid runtime
/// scenario are both supplied. It never receives frame bytes.
final class CalibrationRecorder implements AssistiveAlertObserver {
  CalibrationRecorder(this.configuration, this._sink, {CalibrationClock? clock})
    : _clock = clock ?? DateTime.now;

  factory CalibrationRecorder.disabled() => CalibrationRecorder(
    const CalibrationConfiguration.disabled(),
    const NoopCalibrationEventSink(),
  );

  static const int schemaVersion = 1;
  static const int _maximumPendingAlerts = 16;

  final CalibrationConfiguration configuration;
  final CalibrationEventSink _sink;
  final CalibrationClock _clock;
  final ListQueue<_PendingAlert> _pendingAlerts = ListQueue<_PendingAlert>();

  bool get enabled => configuration.enabled;

  void start() {
    if (!enabled) {
      return;
    }
    _emit('session_started', {
      'policy_version': ProximityPolicy.baselineVersion,
    });
  }

  void recordEvaluation(DetectionBatch batch, ProximityEvaluation evaluation) {
    if (!enabled) {
      return;
    }
    final observedAt = _clock();
    final matchingDetections =
        batch.detections
            .where((item) => item.kind == configuration.expectedKind)
            .toList(growable: false)
          ..sort((a, b) => b.confidence.compareTo(a.confidence));
    final matchingObservations =
        evaluation.observations
            .where((item) => item.kind == configuration.expectedKind)
            .toList(growable: false)
          ..sort((a, b) => b.score.compareTo(a.score));
    final detection = matchingDetections.firstOrNull;
    final observation = matchingObservations.firstOrNull;
    final alert = evaluation.announcedEvent;
    final age = observedAt.difference(batch.capturedAt);

    _emit('frame_evaluated', {
      'captured_at': batch.capturedAt.toUtc().toIso8601String(),
      'observed_at': observedAt.toUtc().toIso8601String(),
      'predicted_band': observation?.band.name ?? 'missed',
      'detected': detection != null,
      'confidence': detection?.confidence,
      'proximity_score': observation?.score,
      'box_bottom': detection?.boundingBox.bottom,
      'box_linear_size': detection == null
          ? null
          : _linearSize(detection.boundingBox),
      'track_frames': observation?.persistenceFrames,
      'announced': alert != null,
      'announced_kind': alert?.kind.name,
      'announced_band': alert?.band.name,
      'preprocessing_us': batch.timings.preprocessing.inMicroseconds,
      'inference_us': batch.timings.inference.inMicroseconds,
      'postprocessing_us': batch.timings.postprocessing.inMicroseconds,
      'vision_total_us': batch.timings.total.inMicroseconds,
      'camera_to_decision_us': age.isNegative ? 0 : age.inMicroseconds,
    });
  }

  @override
  void onAlertQueued(ProximityAlertEvent event, AssistiveAlertMessage message) {
    if (!enabled) {
      return;
    }
    final correlationId = _correlationId(event);
    _pendingAlerts.add(
      _PendingAlert(
        correlationId: correlationId,
        message: message.text,
        sourceAt: event.occurredAt,
      ),
    );
    while (_pendingAlerts.length > _maximumPendingAlerts) {
      _pendingAlerts.removeFirst();
    }
    _emit('alert_queued', {
      'correlation_id': correlationId,
      'source_at': event.occurredAt.toUtc().toIso8601String(),
      'kind': event.kind.name,
      'band': event.band.name,
      'direction': event.direction.name,
      'priority': event.priority,
    });
  }

  void recordSpeechStarted(String message, DateTime startedAt) {
    if (!enabled) {
      return;
    }
    final pending = _removeFirstWhere(
      (candidate) => candidate.message == message,
    );
    final latency = pending == null
        ? null
        : startedAt.difference(pending.sourceAt);
    _emit('speech_started', {
      'correlation_id': pending?.correlationId,
      'started_at': startedAt.toUtc().toIso8601String(),
      'camera_to_speech_start_us': latency == null
          ? null
          : latency.isNegative
          ? 0
          : latency.inMicroseconds,
      'matched_alert': pending != null,
    });
  }

  void _emit(String type, Map<String, Object?> values) {
    _sink.emit({
      'schema_version': schemaVersion,
      'type': type,
      'emitted_at': _clock().toUtc().toIso8601String(),
      'session_id': configuration.sessionId,
      'scenario_id': configuration.scenarioId,
      'dataset_split': configuration.datasetSplit.name,
      'expected_kind': configuration.expectedKind.name,
      'expected_band': configuration.expectedBand.name,
      'lighting': configuration.lighting.name,
      'occlusion': configuration.occlusion.name,
      ...values,
    });
  }

  _PendingAlert? _removeFirstWhere(bool Function(_PendingAlert) predicate) {
    _PendingAlert? match;
    final retained = ListQueue<_PendingAlert>();
    while (_pendingAlerts.isNotEmpty) {
      final candidate = _pendingAlerts.removeFirst();
      if (match == null && predicate(candidate)) {
        match = candidate;
      } else {
        retained.addLast(candidate);
      }
    }
    _pendingAlerts.addAll(retained);
    return match;
  }

  String _correlationId(ProximityAlertEvent event) =>
      '${event.kind.name}-${event.band.name}-'
      '${event.occurredAt.microsecondsSinceEpoch}';

  double _linearSize(NormalizedBoundingBox box) {
    final width = box.right - box.left;
    final height = box.bottom - box.top;
    return math.sqrt(width * height);
  }
}

final class _PendingAlert {
  const _PendingAlert({
    required this.correlationId,
    required this.message,
    required this.sourceAt,
  });

  final String correlationId;
  final String message;
  final DateTime sourceAt;
}
