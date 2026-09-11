import 'dart:convert';
import 'dart:developer' as developer;

import 'package:eyes_mobile/features/calibration/application/calibration_event_sink.dart';

final class DeveloperLogCalibrationEventSink implements CalibrationEventSink {
  const DeveloperLogCalibrationEventSink();

  static const marker = 'EYES_CALIBRATION|';

  @override
  void emit(Map<String, Object?> event) {
    developer.log('$marker${jsonEncode(event)}', name: 'eyes.calibration');
  }
}
