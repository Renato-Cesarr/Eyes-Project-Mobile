import 'package:eyes_mobile/features/assistive_feedback/domain/feedback_preferences.dart';
import 'package:eyes_mobile/features/proximity/application/proximity_policy_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('presets alteram frequência, não thresholds do detector', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(proximityPolicyProvider.notifier);

    controller.configure(
      sensitivity: AlertSensitivityPreset.conservative,
      announceAttention: true,
    );
    final conservative = container.read(proximityPolicyProvider);

    controller.configure(
      sensitivity: AlertSensitivityPreset.fewerAlerts,
      announceAttention: false,
    );
    final fewer = container.read(proximityPolicyProvider);

    expect(conservative.minimumTrackFrames, lessThan(fewer.minimumTrackFrames));
    expect(conservative.sameAlertCooldown, lessThan(fewer.sameAlertCooldown));
    expect(fewer.announceAttention, isFalse);
    expect(fewer.attentionThreshold, conservative.attentionThreshold);
    expect(fewer.veryNearThreshold, conservative.veryNearThreshold);
  });
}
