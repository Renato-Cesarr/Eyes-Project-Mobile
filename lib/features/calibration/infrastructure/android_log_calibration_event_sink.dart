import 'dart:async';
import 'dart:convert';

import 'package:eyes_mobile/features/calibration/application/calibration_event_sink.dart';
import 'package:flutter/services.dart';

final class AndroidLogCalibrationEventSink implements CalibrationEventSink {
  const AndroidLogCalibrationEventSink({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const marker = 'EYES_CALIBRATION|';
  static const _channelName = 'br.com.eyesproject.mobile/calibration';

  final MethodChannel _channel;

  @override
  void emit(Map<String, Object?> event) {
    unawaited(_emitSafely('$marker${jsonEncode(event)}'));
  }

  Future<void> _emitSafely(String payload) async {
    try {
      await _channel.invokeMethod<void>('emitEvent', <String, Object?>{
        'payload': payload,
      });
    } on PlatformException {
      // Calibration telemetry must never interrupt the assistive experience.
    } on MissingPluginException {
      // Unit tests and unsupported platforms intentionally have no native sink.
    }
  }
}
