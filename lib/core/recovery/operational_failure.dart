enum OperationalFailureImpact { degraded, blocking }

enum OperationalRecoveryAction {
  retry,
  openDeviceSettings,
  openFeedbackSettings,
  continueOffline,
  returnToSafety,
}

/// Stable, user-facing failure categories shared by application features.
///
/// Technical exceptions and vendor messages must be mapped to one of these
/// values before they reach presentation. [diagnosticCode] is only for the
/// sanitized logger and must never be rendered or announced.
enum OperationalFailureKind {
  cameraPermissionDenied,
  cameraPermissionPermanentlyDenied,
  cameraRestricted,
  cameraBusy,
  cameraMissing,
  cameraStartupTimeout,
  cameraInitialization,
  cameraStream,
  modelStartupTimeout,
  modelInvalidAsset,
  modelOutOfMemory,
  modelDelegateUnavailable,
  modelRuntime,
  speechUnavailable,
  hapticsUnavailable,
  preferencesUnavailable,
  invalidCredentials,
  sessionExpired,
  networkUnavailable,
  synchronizationPending,
  batteryLow,
  thermalPressure,
  unexpected,
}

final class OperationalFailure {
  const OperationalFailure({
    required this.kind,
    required this.impact,
    required this.primaryAction,
    this.secondaryAction,
    this.diagnosticCode,
  });

  final OperationalFailureKind kind;
  final OperationalFailureImpact impact;
  final OperationalRecoveryAction primaryAction;
  final OperationalRecoveryAction? secondaryAction;
  final String? diagnosticCode;

  bool get blocksAssistiveScan => impact == OperationalFailureImpact.blocking;
}
