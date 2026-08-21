import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:eyes_mobile/features/proximity/application/proximity_controller.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_engine.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_policy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('publica avaliações e limpa toda a sessão ao resetar', () {
    final engine = ProximityEngine(
      policy: ProximityPolicy(minimumTrackFrames: 2),
    );
    final container = ProviderContainer(
      overrides: [proximityEngineProvider.overrideWithValue(engine)],
    );
    addTearDown(container.dispose);
    final controller = container.read(proximityControllerProvider.notifier);

    controller.process(_batch(0));
    controller.process(_batch(1));

    final active = container.read(proximityControllerProvider);
    expect(active.processedFrames, 2);
    expect(active.lastAlert, isNotNull);
    expect(active.recentEvents, hasLength(1));

    controller.reset();

    final reset = container.read(proximityControllerProvider);
    expect(reset.processedFrames, 0);
    expect(reset.lastAlert, isNull);
    expect(reset.recentEvents, isEmpty);
    expect(engine.eventHistory, isEmpty);
  });
}

DetectionBatch _batch(int second) {
  return DetectionBatch(
    detections: [
      DetectedObject(
        kind: DetectedObjectKind.chair,
        confidence: 0.9,
        boundingBox: NormalizedBoundingBox(
          top: 0.05,
          left: 0.20,
          bottom: 0.98,
          right: 0.80,
        ),
      ),
    ],
    capturedAt: DateTime.utc(2026).add(Duration(seconds: second)),
    timings: const DetectionTimings(
      preprocessing: Duration.zero,
      inference: Duration.zero,
      postprocessing: Duration.zero,
    ),
  );
}
