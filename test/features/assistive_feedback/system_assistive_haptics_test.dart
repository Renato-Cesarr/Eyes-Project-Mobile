import 'package:eyes_mobile/features/assistive_feedback/infrastructure/system_assistive_haptics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
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

  test('alerta crítico usa duas pulsações curtas e distintas', () async {
    final delays = <Duration>[];
    final haptics = SystemAssistiveHaptics(
      delay: (duration) async => delays.add(duration),
    );

    await haptics.criticalAlert();

    expect(calls, hasLength(2));
    expect(
      calls.map((call) => call.arguments),
      everyElement('HapticFeedbackType.heavyImpact'),
    );
    expect(delays, [const Duration(milliseconds: 100)]);
  });
}
