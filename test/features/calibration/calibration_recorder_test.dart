import 'package:eyes_mobile/features/assistive_feedback/domain/assistive_alert_message.dart';
import 'package:eyes_mobile/features/calibration/application/calibration_event_sink.dart';
import 'package:eyes_mobile/features/calibration/application/calibration_recorder.dart';
import 'package:eyes_mobile/features/calibration/domain/calibration_configuration.dart';
import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registra avaliação e início real da fala sem pixels', () {
    final sink = _MemorySink();
    final capturedAt = DateTime.utc(2026, 9, 11, 12);
    final recorder = CalibrationRecorder(
      CalibrationConfiguration.enabled(
        sessionId: 'session-01',
        scenarioId: 'chair-attention-01',
        datasetSplit: CalibrationDatasetSplit.evaluation,
        expectedKind: DetectedObjectKind.chair,
        expectedBand: ProximityBand.attention,
        lighting: CalibrationLighting.bright,
        occlusion: CalibrationOcclusion.none,
      ),
      sink,
      clock: () => capturedAt.add(const Duration(milliseconds: 110)),
    );
    final box = NormalizedBoundingBox(
      top: 0.2,
      left: 0.25,
      bottom: 0.8,
      right: 0.75,
    );
    final event = ProximityAlertEvent(
      trackId: 3,
      kind: DetectedObjectKind.chair,
      band: ProximityBand.attention,
      direction: ProximityDirection.ahead,
      score: 0.7,
      priority: 109,
      occurredAt: capturedAt,
    );

    recorder.start();
    recorder.recordEvaluation(
      DetectionBatch(
        detections: [
          DetectedObject(
            kind: DetectedObjectKind.chair,
            confidence: 0.88,
            boundingBox: box,
          ),
        ],
        capturedAt: capturedAt,
        timings: const DetectionTimings(
          preprocessing: Duration(milliseconds: 30),
          inference: Duration(milliseconds: 60),
          postprocessing: Duration(milliseconds: 1),
        ),
      ),
      ProximityEvaluation(
        observations: [
          ProximityObservation(
            trackId: 3,
            kind: DetectedObjectKind.chair,
            band: ProximityBand.attention,
            direction: ProximityDirection.ahead,
            score: 0.7,
            centrality: 1,
            persistenceFrames: 4,
            boundingBox: box,
          ),
        ],
        capturedAt: capturedAt,
        announcedEvent: event,
      ),
    );
    const message = AssistiveAlertMessage(
      text: 'Cadeira próxima, à frente.',
      deduplicationKey: 'chair:attention:ahead',
      priority: 109,
      isCritical: false,
    );
    recorder.onAlertQueued(event, message);
    recorder.recordSpeechStarted(
      message.text,
      capturedAt.add(const Duration(milliseconds: 175)),
    );

    expect(sink.events.map((item) => item['type']), [
      'session_started',
      'frame_evaluated',
      'alert_queued',
      'speech_started',
    ]);
    final frame = sink.events[1];
    expect(frame['predicted_band'], 'attention');
    expect(frame['camera_to_decision_us'], 110000);
    expect(frame['vision_total_us'], 91000);
    expect(frame.keys, isNot(contains('bytes')));
    final speech = sink.events.last;
    expect(speech['camera_to_speech_start_us'], 175000);
    expect(speech['matched_alert'], isTrue);
  });

  test('configuração desabilitada não produz telemetria', () {
    final sink = _MemorySink();
    CalibrationRecorder(
      const CalibrationConfiguration.disabled(),
      sink,
    ).start();

    expect(sink.events, isEmpty);
  });
}

final class _MemorySink implements CalibrationEventSink {
  final List<Map<String, Object?>> events = [];

  @override
  void emit(Map<String, Object?> event) => events.add(event);
}
