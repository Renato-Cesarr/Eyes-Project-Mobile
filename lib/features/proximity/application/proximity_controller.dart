import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:eyes_mobile/features/proximity/application/proximity_state.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_engine.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<ProximityEngine> proximityEngineProvider =
    Provider<ProximityEngine>((Ref ref) => ProximityEngine());

final class ProximityController extends Notifier<ProximityState> {
  @override
  ProximityState build() {
    ref.onDispose(ref.read(proximityEngineProvider).reset);
    return ProximityState();
  }

  ProximityEvaluation process(DetectionBatch batch) {
    final engine = ref.read(proximityEngineProvider);
    final evaluation = engine.process(batch);
    state = ProximityState(
      latestEvaluation: evaluation,
      lastAlert: evaluation.announcedEvent ?? state.lastAlert,
      recentEvents: engine.eventHistory,
      processedFrames: state.processedFrames + 1,
    );
    return evaluation;
  }

  void reset() {
    ref.read(proximityEngineProvider).reset();
    state = ProximityState();
  }
}

final NotifierProvider<ProximityController, ProximityState>
proximityControllerProvider =
    NotifierProvider<ProximityController, ProximityState>(
      ProximityController.new,
    );
