final class SpeechConfiguration {
  const SpeechConfiguration({required this.rate, required this.volume});

  final double rate;
  final double volume;
}

abstract interface class SpeechGateway {
  Future<void> configure(SpeechConfiguration configuration);
  Future<void> speak(String message);
  Future<void> stop();
  Future<void> dispose();
}
