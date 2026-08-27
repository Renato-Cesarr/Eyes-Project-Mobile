import 'package:eyes_mobile/core/accessibility/accessible_feedback_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  test(
    'combines haptic and sound feedback for confirmations and warnings',
    () async {
      final delays = <Duration>[];
      final service = SystemAccessibleFeedbackService(
        delay: (duration) async => delays.add(duration),
      );

      await service.confirm();
      await service.warn();

      expect(calls.map((call) => call.method), <String>[
        'HapticFeedback.vibrate',
        'SystemSound.play',
        'HapticFeedback.vibrate',
        'HapticFeedback.vibrate',
        'SystemSound.play',
      ]);
      expect(calls.first.arguments, 'HapticFeedbackType.lightImpact');
      expect(calls[2].arguments, 'HapticFeedbackType.mediumImpact');
      expect(calls[3].arguments, 'HapticFeedbackType.mediumImpact');
      expect(delays, <Duration>[const Duration(milliseconds: 120)]);
    },
  );

  test('provider returns the system implementation by default', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(accessibleFeedbackServiceProvider),
      isA<SystemAccessibleFeedbackService>(),
    );
  });

  test('disabled preference removes haptics but preserves audible cues', () async {
    final service = SystemAccessibleFeedbackService(
      hapticsEnabled: () => false,
    );

    await service.confirm();
    await service.warn();

    expect(calls.map((call) => call.method), <String>[
      'SystemSound.play',
      'SystemSound.play',
    ]);
  });
}
