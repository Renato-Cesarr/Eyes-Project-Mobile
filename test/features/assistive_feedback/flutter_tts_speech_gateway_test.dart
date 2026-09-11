import 'package:eyes_mobile/features/assistive_feedback/application/speech_gateway.dart';
import 'package:eyes_mobile/features/assistive_feedback/infrastructure/flutter_tts_speech_gateway.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_tts');
  final calls = <MethodCall>[];
  final results = <String, Object?>{};

  setUp(() {
    calls.clear();
    results.clear();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      MethodCall call,
    ) async {
      calls.add(call);
      return results[call.method] ?? 1;
    });
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('configura idioma uma vez e reaplica preferências mutáveis', () async {
    final gateway = FlutterTtsSpeechGateway();

    await gateway.configure(const SpeechConfiguration(rate: 0.5, volume: 1));
    await gateway.configure(const SpeechConfiguration(rate: 0.6, volume: 0.8));

    expect(calls.where((call) => call.method == 'setLanguage'), hasLength(1));
    expect(
      calls.where((call) => call.method == 'awaitSpeakCompletion'),
      hasLength(1),
    );
    expect(calls.where((call) => call.method == 'setSpeechRate'), hasLength(2));
    expect(calls.where((call) => call.method == 'setVolume'), hasLength(2));
    expect(calls.where((call) => call.method == 'setPitch'), hasLength(2));
  });

  test(
    'reproduz e interrompe a voz quando o plugin confirma sucesso',
    () async {
      final gateway = FlutterTtsSpeechGateway();

      await gateway.speak('Cadeira próxima à direita.');
      await gateway.stop();

      expect(calls.map((call) => call.method), <String>['speak', 'stop']);
    },
  );

  test('classifica retorno zero da fala como interrupção normal', () async {
    results['speak'] = 0;
    final gateway = FlutterTtsSpeechGateway();

    await expectLater(
      gateway.speak('Fala cancelada'),
      throwsA(isA<SpeechPlaybackInterruptedException>()),
    );
  });

  test('propaga falha real ao configurar o mecanismo de voz', () async {
    results['setLanguage'] = 0;
    final gateway = FlutterTtsSpeechGateway();

    await expectLater(
      gateway.configure(const SpeechConfiguration(rate: 0.5, volume: 1)),
      throwsA(isA<SpeechGatewayException>()),
    );
  });

  test('observa o início nativo da fala com relógio injetado', () async {
    final starts = <(String, DateTime)>[];
    final startedAt = DateTime.utc(2026, 9, 11, 12);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      MethodCall call,
    ) async {
      calls.add(call);
      if (call.method == 'speak') {
        await binding.defaultBinaryMessenger.handlePlatformMessage(
          channel.name,
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('speak.onStart'),
          ),
          (_) {},
        );
      }
      return 1;
    });
    final gateway = FlutterTtsSpeechGateway(
      clock: () => startedAt,
      onPlaybackStarted: (message, timestamp) {
        starts.add((message, timestamp));
      },
    );
    await gateway.configure(const SpeechConfiguration(rate: 0.5, volume: 1));

    await gateway.speak('Cadeira próxima à direita.');

    expect(starts, [('Cadeira próxima à direita.', startedAt)]);
  });
}
