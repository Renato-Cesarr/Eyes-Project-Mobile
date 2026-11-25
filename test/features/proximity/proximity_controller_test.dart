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

  test('preserva uma perda breve e limpa só o aviso do objeto ausente', () {
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
    final alert = container.read(proximityControllerProvider).lastAlert;
    expect(alert, isNotNull);

    controller.process(_batch(2, visible: false));
    expect(container.read(proximityControllerProvider).lastAlert, same(alert));
    controller.process(_batch(3));
    expect(container.read(proximityControllerProvider).lastAlert, same(alert));

    // A different track of the same class does not keep the old alert alive.
    controller.process(_batch(4, elsewhere: true));
    expect(container.read(proximityControllerProvider).lastAlert, same(alert));
    controller.process(_batch(5, elsewhere: true));
    final cleared = container.read(proximityControllerProvider);
    expect(cleared.lastAlert, isNull);
    expect(cleared.recentEvents, [alert]);

    controller.process(_batch(6));
    expect(container.read(proximityControllerProvider).lastAlert, isNull);
  });
}

DetectionBatch _batch(
  int second, {
  bool visible = true,
  bool elsewhere = false,
}) {
  return DetectionBatch(
    detections: [
      if (visible)
        DetectedObject(
          kind: DetectedObjectKind.chair,
          confidence: 0.9,
          boundingBox: NormalizedBoundingBox(
            top: 0.05,
            left: elsewhere ? 0.81 : 0.20,
            bottom: 0.98,
            right: elsewhere ? 1.0 : 0.80,
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
