abstract interface class CalibrationEventSink {
  void emit(Map<String, Object?> event);
}

final class NoopCalibrationEventSink implements CalibrationEventSink {
  const NoopCalibrationEventSink();

  @override
  void emit(Map<String, Object?> event) {}
}
