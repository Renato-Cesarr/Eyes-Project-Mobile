import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_engine.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_models.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProximityEngine', () {
    test('não anuncia uma detecção presente em apenas um frame', () {
      final engine = ProximityEngine();

      final evaluation = engine.process(
        _batch(0, [_veryNear(DetectedObjectKind.chair)]),
      );

      expect(evaluation.announcedEvent, isNull);
      expect(engine.eventHistory, isEmpty);
    });

    test('só anuncia depois da persistência temporal mínima', () {
      final engine = ProximityEngine();

      expect(
        engine
            .process(_batch(0, [_veryNear(DetectedObjectKind.chair)]))
            .announcedEvent,
        isNull,
      );
      expect(
        engine
            .process(_batch(1, [_veryNear(DetectedObjectKind.chair)]))
            .announcedEvent,
        isNull,
      );
      final event = engine
          .process(_batch(2, [_veryNear(DetectedObjectKind.chair)]))
          .announcedEvent;

      expect(event?.kind, DetectedObjectKind.chair);
      expect(event?.band, ProximityBand.veryNear);
    });

    test('replay da mesma sequência produz eventos idênticos', () {
      final sequence = <DetectionBatch>[
        _batch(0, [_attention(DetectedObjectKind.person)]),
        _batch(1, [_attention(DetectedObjectKind.person)]),
        _batch(2, [_attention(DetectedObjectKind.person)]),
        _batch(3, [_veryNear(DetectedObjectKind.person)]),
        _batch(4, [_veryNear(DetectedObjectKind.person)]),
        _batch(8, [_veryNear(DetectedObjectKind.person)]),
      ];

      List<String> replay() {
        final engine = ProximityEngine();
        return sequence
            .map(engine.process)
            .map((evaluation) => evaluation.announcedEvent)
            .whereType<ProximityAlertEvent>()
            .map(
              (event) =>
                  '${event.trackId}:${event.kind.name}:${event.band.name}:'
                  '${event.occurredAt.toIso8601String()}',
            )
            .toList(growable: false);
      }

      expect(replay(), replay());
    });

    test('associa por IoU e classe sem misturar objetos sobrepostos', () {
      final engine = ProximityEngine();
      final first = engine.process(
        _batch(0, [
          _box(DetectedObjectKind.chair, 0.20, 0.20, 0.60, 0.90),
          _box(DetectedObjectKind.person, 0.20, 0.20, 0.60, 0.90),
        ]),
      );
      final second = engine.process(
        _batch(1, [
          _box(DetectedObjectKind.chair, 0.22, 0.20, 0.62, 0.90),
          _box(DetectedObjectKind.person, 0.22, 0.20, 0.62, 0.90),
        ]),
      );

      expect(
        second.observations.map((observation) => observation.trackId),
        first.observations.map((observation) => observation.trackId),
      );
      expect(
        second.observations.map((observation) => observation.kind).toSet(),
        {DetectedObjectKind.chair, DetectedObjectKind.person},
      );
    });

    test('histerese exige persistência antes de reduzir a faixa', () {
      final engine = ProximityEngine(
        policy: ProximityPolicy(
          emaAlpha: 1,
          iouThreshold: 0.01,
          minimumTrackFrames: 2,
          transitionConfirmationFrames: 2,
        ),
      );
      engine.process(_batch(0, [_veryNear(DetectedObjectKind.chair)]));
      final stable = engine.process(
        _batch(1, [_veryNear(DetectedObjectKind.chair)]),
      );
      expect(stable.observations.single.score, greaterThan(0.83));
      expect(stable.observations.single.persistenceFrames, 2);
      expect(stable.observations.single.band, ProximityBand.veryNear);

      final firstDistant = engine.process(
        _batch(2, [_distant(DetectedObjectKind.chair)]),
      );
      final confirmedDistant = engine.process(
        _batch(3, [_distant(DetectedObjectKind.chair)]),
      );

      expect(firstDistant.observations.single.band, ProximityBand.veryNear);
      expect(confirmedDistant.observations.single.band, ProximityBand.distant);
    });

    test(
      'cooldown elimina repetição e libera novo alerta após o intervalo',
      () {
        final engine = ProximityEngine();
        ProximityAlertEvent? eventAt(int second) => engine
            .process(_batch(second, [_veryNear(DetectedObjectKind.chair)]))
            .announcedEvent;

        expect(eventAt(0), isNull);
        expect(eventAt(1), isNull);
        expect(eventAt(2), isNotNull);
        expect(eventAt(3), isNull);
        expect(eventAt(7), isNull);
        expect(eventAt(8), isNotNull);
      },
    );

    test('deduplica a mesma classe e faixa mesmo em um novo track', () {
      final engine = ProximityEngine();
      for (var frame = 0; frame < 3; frame++) {
        engine.process(
          _batch(frame, [
            _box(DetectedObjectKind.chair, 0.05, 0.05, 0.55, 0.98),
          ]),
        );
      }
      expect(engine.eventHistory, hasLength(1));

      for (var frame = 3; frame < 6; frame++) {
        engine.process(
          _batch(frame, [
            _box(DetectedObjectKind.chair, 0.55, 0.05, 0.98, 0.98),
          ]),
        );
      }

      expect(engine.eventHistory, hasLength(1));
    });

    test('permite desativar alertas informativos sem ocultar críticos', () {
      final engine = ProximityEngine(
        policy: ProximityPolicy(announceAttention: false),
      );
      for (var frame = 0; frame < 3; frame++) {
        engine.process(_batch(frame, [_attention(DetectedObjectKind.person)]));
      }
      expect(engine.eventHistory, isEmpty);

      for (var frame = 3; frame < 8; frame++) {
        engine.process(_batch(frame, [_veryNear(DetectedObjectKind.person)]));
      }

      expect(engine.eventHistory.single.band, ProximityBand.veryNear);
    });

    test('alerta muito próximo preempta alerta de atenção', () {
      final engine = ProximityEngine();
      for (var frame = 0; frame < 3; frame++) {
        engine.process(
          _batchMilliseconds(frame * 100, [
            _attention(DetectedObjectKind.person),
          ]),
        );
      }
      expect(engine.eventHistory.single.band, ProximityBand.attention);

      ProximityAlertEvent? critical;
      for (var frame = 3; frame < 6; frame++) {
        critical = engine
            .process(
              _batchMilliseconds(frame * 100, [
                _attention(DetectedObjectKind.person),
                _veryNear(DetectedObjectKind.chair),
              ]),
            )
            .announcedEvent;
      }

      expect(critical?.kind, DetectedObjectKind.chair);
      expect(critical?.band, ProximityBand.veryNear);
      expect(
        critical!.occurredAt.difference(engine.eventHistory.first.occurredAt),
        lessThan(const Duration(seconds: 2)),
      );
    });

    test(
      'prioriza faixa, risco e centralidade e limita um evento por frame',
      () {
        final engine = ProximityEngine();
        ProximityEvaluation? evaluation;
        for (var frame = 0; frame < 3; frame++) {
          evaluation = engine.process(
            _batch(frame, [
              _box(DetectedObjectKind.backpack, 0.00, 0.05, 0.45, 0.98),
              _box(DetectedObjectKind.chair, 0.25, 0.05, 0.75, 0.98),
            ]),
          );
        }

        expect(evaluation?.announcedEvent?.kind, DetectedObjectKind.chair);
        expect(engine.eventHistory, hasLength(1));
      },
    );

    test('histórico é limitado e não armazena bounding boxes ou imagens', () {
      final engine = ProximityEngine(
        policy: ProximityPolicy(
          minimumTrackFrames: 2,
          globalMinimumInterval: Duration.zero,
          sameAlertCooldown: Duration.zero,
          maximumEventHistory: 2,
        ),
      );
      for (var frame = 0; frame < 4; frame++) {
        engine.process(_batch(frame, [_veryNear(DetectedObjectKind.chair)]));
      }

      expect(engine.eventHistory, hasLength(2));
      expect(
        engine.eventHistory.every((event) => event.score.isFinite),
        isTrue,
      );
    });

    test('rejeita timestamps regressivos dentro da mesma sessão', () {
      final engine = ProximityEngine();
      engine.process(_batch(1, const []));

      expect(() => engine.process(_batch(0, const [])), throwsArgumentError);
    });
  });
}

DetectionBatch _batch(int second, List<DetectedObject> detections) =>
    _batchMilliseconds(second * 1000, detections);

DetectionBatch _batchMilliseconds(
  int milliseconds,
  List<DetectedObject> detections,
) {
  return DetectionBatch(
    detections: detections,
    capturedAt: DateTime.utc(2026).add(Duration(milliseconds: milliseconds)),
    timings: const DetectionTimings(
      preprocessing: Duration.zero,
      inference: Duration.zero,
      postprocessing: Duration.zero,
    ),
  );
}

DetectedObject _distant(DetectedObjectKind kind) =>
    _box(kind, 0.45, 0.30, 0.55, 0.50);

DetectedObject _attention(DetectedObjectKind kind) =>
    _box(kind, 0.35, 0.25, 0.65, 0.75);

DetectedObject _veryNear(DetectedObjectKind kind) =>
    _box(kind, 0.20, 0.05, 0.80, 0.98);

DetectedObject _box(
  DetectedObjectKind kind,
  double left,
  double top,
  double right,
  double bottom,
) {
  return DetectedObject(
    kind: kind,
    confidence: 0.9,
    boundingBox: NormalizedBoundingBox(
      top: top,
      left: left,
      bottom: bottom,
      right: right,
    ),
  );
}
