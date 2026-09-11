import 'package:eyes_mobile/features/calibration/domain/calibration_configuration.dart';
import 'package:eyes_mobile/features/calibration/infrastructure/platform_calibration_configuration_source.dart';
import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('calibration-test');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('build comum não consulta configuração nativa', () async {
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls++;
          return null;
        });

    final configuration = await const PlatformCalibrationConfigurationSource(
      channel,
      false,
    ).load();

    expect(configuration.enabled, isFalse);
    expect(calls, 0);
  });

  test('mapeia cenário nativo somente no build de calibração', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'getSessionConfiguration');
          return <String, Object?>{
            'enabled': true,
            'sessionId': 'ren37-session-01',
            'scenarioId': 'chair-very-near-01',
            'datasetSplit': 'evaluation',
            'expectedKind': 'chair',
            'expectedBand': 'veryNear',
            'lighting': 'dim',
            'occlusion': 'partial',
          };
        });

    final configuration = await const PlatformCalibrationConfigurationSource(
      channel,
      true,
    ).load();

    expect(configuration.enabled, isTrue);
    expect(configuration.expectedKind, DetectedObjectKind.chair);
    expect(configuration.expectedBand, ProximityBand.veryNear);
    expect(configuration.lighting, CalibrationLighting.dim);
  });

  test('rejeita metadados nativos incompletos', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => {'enabled': true});

    await expectLater(
      const PlatformCalibrationConfigurationSource(channel, true).load(),
      throwsA(isA<CalibrationConfigurationException>()),
    );
  });
}
