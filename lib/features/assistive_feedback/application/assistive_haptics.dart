abstract interface class AssistiveHaptics {
  Future<bool> isAvailable();
  Future<void> confirm();
  Future<void> warning();
  Future<void> criticalAlert();
}
