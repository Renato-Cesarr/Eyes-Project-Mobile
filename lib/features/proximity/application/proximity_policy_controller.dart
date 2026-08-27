import 'package:eyes_mobile/features/assistive_feedback/domain/feedback_preferences.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_policy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class ProximityPolicyController extends Notifier<ProximityPolicy> {
  @override
  ProximityPolicy build() => ProximityPolicy();

  void configure({
    required AlertSensitivityPreset sensitivity,
    required bool announceAttention,
  }) {
    state = switch (sensitivity) {
      AlertSensitivityPreset.conservative => ProximityPolicy(
        minimumTrackFrames: 2,
        globalMinimumInterval: const Duration(milliseconds: 1500),
        sameAlertCooldown: const Duration(seconds: 4),
        announceAttention: announceAttention,
      ),
      AlertSensitivityPreset.balanced => ProximityPolicy(
        announceAttention: announceAttention,
      ),
      AlertSensitivityPreset.fewerAlerts => ProximityPolicy(
        minimumTrackFrames: 4,
        transitionConfirmationFrames: 3,
        globalMinimumInterval: const Duration(seconds: 3),
        sameAlertCooldown: const Duration(seconds: 10),
        announceAttention: announceAttention,
      ),
    };
  }
}

final NotifierProvider<ProximityPolicyController, ProximityPolicy>
proximityPolicyProvider =
    NotifierProvider<ProximityPolicyController, ProximityPolicy>(
      ProximityPolicyController.new,
    );
