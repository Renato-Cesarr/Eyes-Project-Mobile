import 'dart:async';

import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:eyes_mobile/features/proximity/application/proximity_policy_controller.dart';
import 'package:eyes_mobile/features/proximity/application/proximity_state.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_engine.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_models.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_policy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<ProximityEngine> proximityEngineProvider =
    Provider<ProximityEngine>(
      (Ref ref) => ProximityEngine(policy: ref.watch(proximityPolicyProvider)),
    );

final class ProximityController extends Notifier<ProximityState> {
  static const _alertPresenceTimeout = Duration(seconds: 1);
  static const _missingFramesToHideAlert = 2;

  Timer? _alertExpiry;
  int _missingAlertFrames = 0;

  @override
  ProximityState build() {
    ref.listen<ProximityPolicy>(proximityPolicyProvider, (previous, next) {
      reset();
    });
    final engine = ref.read(proximityEngineProvider);
    ref.onDispose(() {
      _resetAlertTracking();
      engine.reset();
    });
    return ProximityState();
  }

  ProximityEvaluation process(DetectionBatch batch) {
    final engine = ref.read(proximityEngineProvider);
    final evaluation = engine.process(batch);
    var activeAlert = evaluation.announcedEvent ?? state.lastAlert;
    if (activeAlert case final alert?) {
      final stillVisible = evaluation.observations.any(
        (observation) =>
            observation.trackId == alert.trackId &&
            observation.band != ProximityBand.distant,
      );
      if (stillVisible) {
        _missingAlertFrames = 0;
        _alertExpiry?.cancel();
        _alertExpiry = Timer(_alertPresenceTimeout, _expireAlert);
      } else if (++_missingAlertFrames >= _missingFramesToHideAlert) {
        _resetAlertTracking();
        activeAlert = null;
      }
    }
    state = ProximityState(
      latestEvaluation: evaluation,
      lastAlert: activeAlert,
      recentEvents: engine.eventHistory,
      processedFrames: state.processedFrames + 1,
    );
    return evaluation;
  }

  void reset() {
    _resetAlertTracking();
    ref.read(proximityEngineProvider).reset();
    state = ProximityState();
  }

  void _expireAlert() {
    _resetAlertTracking();
    state = ProximityState(
      latestEvaluation: state.latestEvaluation,
      recentEvents: state.recentEvents,
      processedFrames: state.processedFrames,
    );
  }

  void _resetAlertTracking() {
    _alertExpiry?.cancel();
    _alertExpiry = null;
    _missingAlertFrames = 0;
  }
}

final NotifierProvider<ProximityController, ProximityState>
proximityControllerProvider =
    NotifierProvider<ProximityController, ProximityState>(
      ProximityController.new,
    );
