import 'package:eyes_mobile/features/assistive_feedback/application/assistive_feedback_controller.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/assistive_feedback_state.dart';
import 'package:eyes_mobile/features/proximity/application/proximity_controller.dart';
import 'package:eyes_mobile/features/proximity/application/proximity_policy_controller.dart';
import 'package:eyes_mobile/features/proximity/application/proximity_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Connects the two application features without coupling either domain to
/// Riverpod, plugins or persistence details.
final Provider<void> assistiveFeedbackBindingProvider = Provider<void>((
  Ref ref,
) {
  ref.listen<AsyncValue<AssistiveFeedbackState>>(
    assistiveFeedbackControllerProvider,
    (previous, next) {
      final preferences = next.asData?.value.preferences;
      if (preferences != null) {
        ref
            .read(proximityPolicyProvider.notifier)
            .configure(
              sensitivity: preferences.sensitivity,
              announceAttention: preferences.announceAttention,
            );
      }
    },
    fireImmediately: true,
  );
  ref.listen<ProximityState>(proximityControllerProvider, (previous, next) {
    final event = next.lastAlert;
    if (event == null || identical(event, previous?.lastAlert)) {
      return;
    }
    ref.read(assistiveFeedbackControllerProvider.notifier).handleAlert(event);
  });
});
