import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_models.dart';

enum CalibrationDatasetSplit { calibration, evaluation }

enum CalibrationLighting { bright, dim, backlit }

enum CalibrationOcclusion { none, partial }

/// Ground-truth metadata supplied by the evaluator for one controlled scene.
///
/// This metadata is never shown to the product user and does not claim a
/// metric distance. It exists only to evaluate the three relative bands.
final class CalibrationConfiguration {
  const CalibrationConfiguration._({
    required this.enabled,
    required this.sessionId,
    required this.scenarioId,
    required this.datasetSplit,
    required this.expectedKind,
    required this.expectedBand,
    required this.lighting,
    required this.occlusion,
  });

  const CalibrationConfiguration.disabled()
    : this._(
        enabled: false,
        sessionId: 'disabled',
        scenarioId: 'disabled',
        datasetSplit: CalibrationDatasetSplit.calibration,
        expectedKind: DetectedObjectKind.chair,
        expectedBand: ProximityBand.distant,
        lighting: CalibrationLighting.bright,
        occlusion: CalibrationOcclusion.none,
      );

  factory CalibrationConfiguration.enabled({
    required String sessionId,
    required String scenarioId,
    required CalibrationDatasetSplit datasetSplit,
    required DetectedObjectKind expectedKind,
    required ProximityBand expectedBand,
    required CalibrationLighting lighting,
    required CalibrationOcclusion occlusion,
  }) {
    final identifierPattern = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._-]{0,79}$');
    if (!identifierPattern.hasMatch(sessionId)) {
      throw ArgumentError.value(
        sessionId,
        'sessionId',
        'identificador inválido',
      );
    }
    if (!identifierPattern.hasMatch(scenarioId)) {
      throw ArgumentError.value(
        scenarioId,
        'scenarioId',
        'identificador inválido',
      );
    }
    return CalibrationConfiguration._(
      enabled: true,
      sessionId: sessionId,
      scenarioId: scenarioId,
      datasetSplit: datasetSplit,
      expectedKind: expectedKind,
      expectedBand: expectedBand,
      lighting: lighting,
      occlusion: occlusion,
    );
  }

  final bool enabled;
  final String sessionId;
  final String scenarioId;
  final CalibrationDatasetSplit datasetSplit;
  final DetectedObjectKind expectedKind;
  final ProximityBand expectedBand;
  final CalibrationLighting lighting;
  final CalibrationOcclusion occlusion;
}
