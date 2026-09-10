import 'package:eyes_mobile/features/assistive_feedback/infrastructure/system_assistive_haptics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/assistive_haptics');
  final calls = <MethodCall>[];
  var available = true;

  setUp(() {
    calls.clear();
    available = true;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      MethodCall call,
    ) async {
      calls.add(call);
      return switch (call.method) {
        'isAvailable' => available,
        'vibrate' => available,
        _ => null,
      };
    });
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('consulta a capacidade real do aparelho', () async {
    final haptics = SystemAssistiveHaptics(channel: channel);

    expect(await haptics.isAvailable(), isTrue);
    available = false;
    expect(await haptics.isAvailable(), isFalse);
  });

  test('envia padrões explícitos e distintos ao Android', () async {
    final haptics = SystemAssistiveHaptics(channel: channel);

    await haptics.confirm();
    await haptics.warning();
    await haptics.criticalAlert();

    expect(calls.map((call) => call.arguments), <Object?>[
      <String, Object>{'pattern': 'confirm'},
      <String, Object>{'pattern': 'warning'},
      <String, Object>{'pattern': 'critical'},
    ]);
  });

  test('não confirma entrega quando o vibrador está indisponível', () async {
    available = false;
    final haptics = SystemAssistiveHaptics(channel: channel);

    await expectLater(
      haptics.confirm(),
      throwsA(isA<HapticsUnavailableException>()),
    );
  });
}
