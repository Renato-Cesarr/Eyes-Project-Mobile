abstract interface class AssistiveHaptics {
  Future<void> confirm();
  Future<void> warning();
  Future<void> criticalAlert();
}
