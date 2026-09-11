import 'package:eyes_mobile/features/calibration/domain/calibration_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calcula matriz, percentis e taxas sem reinterpretar as faixas', () {
    final events = <Map<String, Object?>>[
      _event('session_started', 0),
      _frame(100, expected: 'attention', predicted: 'attention'),
      _frame(200, expected: 'attention', predicted: 'missed'),
      _frame(300, expected: 'distant', predicted: 'distant', announced: true),
      _alert(400),
      _alert(500),
      _speech(450, latency: 280000),
      _speech(550, latency: 320000),
    ];

    final analysis = CalibrationAnalysis.fromEvents(events);

    expect(analysis.frameCount, 3);
    expect(analysis.confusionMatrix['attention'], {
      'attention': 1,
      'missed': 1,
    });
    expect(analysis.missedHazardRate, 0.5);
    expect(analysis.falseAlertRate, 1);
    expect(analysis.repeatedAlertCount, 1);
    expect(analysis.firstAlertLatency, const Duration(milliseconds: 400));
    expect(
      analysis.percentile(analysis.cameraToSpeechStartMicroseconds, 50),
      300000,
    );
  });

  test('percentil rejeita faixa inválida', () {
    final analysis = CalibrationAnalysis.fromEvents([
      _frame(100, expected: 'distant', predicted: 'distant'),
    ]);

    expect(
      () => analysis.percentile(analysis.cameraToDecisionMicroseconds, 101),
      throwsRangeError,
    );
  });
}

Map<String, Object?> _event(String type, int milliseconds) => {
  'type': type,
  'session_id': 'session-01',
  'emitted_at': DateTime.utc(
    2026,
    9,
    11,
  ).add(Duration(milliseconds: milliseconds)).toIso8601String(),
};

Map<String, Object?> _frame(
  int milliseconds, {
  required String expected,
  required String predicted,
  bool announced = false,
}) => {
  ..._event('frame_evaluated', milliseconds),
  'expected_band': expected,
  'predicted_band': predicted,
  'announced': announced,
  'camera_to_decision_us': milliseconds * 1000,
  'preprocessing_us': 30000,
  'inference_us': 60000,
  'vision_total_us': 90000,
};

Map<String, Object?> _alert(int milliseconds) => {
  ..._event('alert_queued', milliseconds),
  'source_at': DateTime.utc(
    2026,
    9,
    11,
  ).add(Duration(milliseconds: milliseconds)).toIso8601String(),
  'kind': 'chair',
  'band': 'attention',
  'direction': 'ahead',
};

Map<String, Object?> _speech(int milliseconds, {required int latency}) => {
  ..._event('speech_started', milliseconds),
  'matched_alert': true,
  'camera_to_speech_start_us': latency,
};
