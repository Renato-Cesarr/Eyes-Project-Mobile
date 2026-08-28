import 'package:eyes_mobile/features/scanning/application/scan_transition_feedback.dart';
import 'package:eyes_mobile/features/scanning/infrastructure/system_scan_transition_feedback.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        calls.add(call);
        return null;
      },
    );
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  test('uses distinct haptic patterns for each scan transition', () async {
    final feedback = SystemScanTransitionFeedback();

    await feedback.deliver(ScanTransition.started);
    await feedback.deliver(ScanTransition.paused);
    await feedback.deliver(ScanTransition.ended);

    final haptics = calls
        .where((call) => call.method == 'HapticFeedback.vibrate')
        .map((call) => call.arguments);
    expect(haptics, <Object?>[
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.mediumImpact',
    ]);
    expect(
      calls.where((call) => call.method == 'SystemSound.play'),
      hasLength(3),
    );
  });

  test('keeps sound cues when haptics are disabled by preference', () async {
    final feedback = SystemScanTransitionFeedback(hapticsEnabled: () => false);

    await feedback.deliver(ScanTransition.started);

    expect(calls, hasLength(1));
    expect(calls.single.method, 'SystemSound.play');
  });
}
