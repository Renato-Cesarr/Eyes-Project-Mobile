import 'dart:async';
import 'dart:convert';

import 'package:eyes_mobile/features/calibration/infrastructure/android_log_calibration_event_sink.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('calibration-log-test');

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('envia JSON marcado para o coletor nativo', () async {
    final received = Completer<MethodCall>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          received.complete(call);
          return null;
        });
    const sink = AndroidLogCalibrationEventSink(channel: channel);

    sink.emit(<String, Object?>{'type': 'session_started', 'schema_version': 1});

    final call = await received.future;
    expect(call.method, 'emitEvent');
    final arguments = call.arguments as Map<Object?, Object?>;
    final payload = arguments['payload']! as String;
    expect(payload, startsWith(AndroidLogCalibrationEventSink.marker));
    expect(
      jsonDecode(payload.substring(AndroidLogCalibrationEventSink.marker.length)),
      <String, Object?>{'type': 'session_started', 'schema_version': 1},
    );
  });
}
