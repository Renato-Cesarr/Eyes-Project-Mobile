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
      const service = SystemAccessibleFeedbackService();

      await service.confirm();
      await service.warn();

      expect(calls.map((call) => call.method), <String>[
        'HapticFeedback.vibrate',
        'SystemSound.play',
        'HapticFeedback.vibrate',
        'SystemSound.play',
      ]);
      expect(calls.first.arguments, 'HapticFeedbackType.mediumImpact');
      expect(calls[2].arguments, 'HapticFeedbackType.heavyImpact');
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
}
