import 'package:eyes_mobile/features/calibration/domain/calibration_configuration.dart';
import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('configuração válida mantém metadados controlados do ensaio', () {
    final configuration = CalibrationConfiguration.enabled(
      sessionId: 'ren37-20260911-01',
      scenarioId: 'chair-attention-bright-clear-01',
      datasetSplit: CalibrationDatasetSplit.evaluation,
      expectedKind: DetectedObjectKind.chair,
      expectedBand: ProximityBand.attention,
      lighting: CalibrationLighting.bright,
      occlusion: CalibrationOcclusion.none,
    );

    expect(configuration.enabled, isTrue);
    expect(configuration.datasetSplit, CalibrationDatasetSplit.evaluation);
    expect(configuration.expectedKind, DetectedObjectKind.chair);
  });

  test('identificadores livres ou potencialmente sensíveis são rejeitados', () {
    expect(
      () => CalibrationConfiguration.enabled(
        sessionId: 'nome do aluno',
        scenarioId: 'chair-01',
        datasetSplit: CalibrationDatasetSplit.calibration,
        expectedKind: DetectedObjectKind.chair,
        expectedBand: ProximityBand.distant,
        lighting: CalibrationLighting.dim,
        occlusion: CalibrationOcclusion.partial,
      ),
      throwsArgumentError,
    );
  });
}
