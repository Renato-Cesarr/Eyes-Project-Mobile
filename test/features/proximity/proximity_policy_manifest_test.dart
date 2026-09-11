import 'dart:convert';
import 'dart:io';

import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('manifesto versionado representa o baseline executado pelo app', () {
    final document =
        jsonDecode(File('config/proximity-policy.v1.json').readAsStringSync())
            as Map<String, Object?>;
    final parameters = document['parameters']! as Map<String, Object?>;
    final calibrations = document['classCalibration']! as Map<String, Object?>;
    final policy = ProximityPolicy();

    expect(document['policyVersion'], ProximityPolicy.baselineVersion);
    expect(parameters['iouThreshold'], policy.iouThreshold);
    expect(parameters['emaAlpha'], policy.emaAlpha);
    expect(parameters['attentionThreshold'], policy.attentionThreshold);
    expect(parameters['veryNearThreshold'], policy.veryNearThreshold);
    expect(parameters['hysteresisMargin'], policy.hysteresisMargin);
    expect(parameters['minimumTrackFrames'], policy.minimumTrackFrames);
    expect(
      parameters['transitionConfirmationFrames'],
      policy.transitionConfirmationFrames,
    );
    expect(parameters['maximumMissedFrames'], policy.maximumMissedFrames);
    expect(
      parameters['globalMinimumIntervalMs'],
      policy.globalMinimumInterval.inMilliseconds,
    );
    expect(
      parameters['sameAlertCooldownMs'],
      policy.sameAlertCooldown.inMilliseconds,
    );

    for (final kind in DetectedObjectKind.values) {
      final expected = calibrations[kind.name]! as Map<String, Object?>;
      final actual = policy.calibrations[kind]!;
      expect(expected['referenceLinearSize'], actual.referenceLinearSize);
      expect(expected['riskWeight'], actual.riskWeight);
    }
  });
}
