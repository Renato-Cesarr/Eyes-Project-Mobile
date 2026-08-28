import 'package:eyes_mobile/core/recovery/operational_failure.dart';
import 'package:eyes_mobile/l10n/generated/app_localizations.dart';

final class RecoveryContent {
  const RecoveryContent({required this.title, required this.message});

  final String title;
  final String message;
}

abstract final class RecoveryContentResolver {
  static RecoveryContent resolve(
    AppLocalizations l10n,
    OperationalFailureKind kind,
  ) => switch (kind) {
    OperationalFailureKind.cameraPermissionDenied => RecoveryContent(
      title: l10n.recoveryCameraPermissionTitle,
      message: l10n.cameraPermissionDeniedHelp,
    ),
    OperationalFailureKind.cameraPermissionPermanentlyDenied => RecoveryContent(
      title: l10n.recoveryCameraPermissionBlockedTitle,
      message: l10n.cameraPermissionPermanentlyDeniedHelp,
    ),
    OperationalFailureKind.cameraRestricted => RecoveryContent(
      title: l10n.recoveryCameraRestrictedTitle,
      message: l10n.cameraPermissionRestrictedHelp,
    ),
    OperationalFailureKind.cameraBusy => RecoveryContent(
      title: l10n.cameraStatusBusy,
      message: l10n.cameraBusyHelp,
    ),
    OperationalFailureKind.cameraMissing => RecoveryContent(
      title: l10n.cameraStatusUnavailable,
      message: l10n.cameraMissingHelp,
    ),
    OperationalFailureKind.cameraStartupTimeout => RecoveryContent(
      title: l10n.recoveryCameraTimeoutTitle,
      message: l10n.cameraTimeoutHelp,
    ),
    OperationalFailureKind.cameraInitialization => RecoveryContent(
      title: l10n.cameraStatusUnavailable,
      message: l10n.cameraInitializationHelp,
    ),
    OperationalFailureKind.cameraStream => RecoveryContent(
      title: l10n.recoveryCameraInterruptedTitle,
      message: l10n.cameraStreamHelp,
    ),
    OperationalFailureKind.modelStartupTimeout => RecoveryContent(
      title: l10n.recoveryModelTimeoutTitle,
      message: l10n.recoveryModelTimeoutMessage,
    ),
    OperationalFailureKind.modelInvalidAsset => RecoveryContent(
      title: l10n.recoveryModelUnavailableTitle,
      message: l10n.recoveryModelInvalidMessage,
    ),
    OperationalFailureKind.modelOutOfMemory => RecoveryContent(
      title: l10n.recoveryModelUnavailableTitle,
      message: l10n.recoveryModelMemoryMessage,
    ),
    OperationalFailureKind.modelDelegateUnavailable => RecoveryContent(
      title: l10n.recoveryModelUnavailableTitle,
      message: l10n.recoveryModelDelegateMessage,
    ),
    OperationalFailureKind.modelRuntime => RecoveryContent(
      title: l10n.visionFailed,
      message: l10n.visionFailedHelp,
    ),
    OperationalFailureKind.speechUnavailable => RecoveryContent(
      title: l10n.recoverySpeechTitle,
      message: l10n.recoverySpeechMessage,
    ),
    OperationalFailureKind.hapticsUnavailable => RecoveryContent(
      title: l10n.recoveryHapticsTitle,
      message: l10n.recoveryHapticsMessage,
    ),
    OperationalFailureKind.preferencesUnavailable => RecoveryContent(
      title: l10n.recoveryPreferencesTitle,
      message: l10n.recoveryPreferencesMessage,
    ),
    OperationalFailureKind.invalidCredentials => RecoveryContent(
      title: l10n.recoveryLoginTitle,
      message: l10n.recoveryInvalidCredentialsMessage,
    ),
    OperationalFailureKind.sessionExpired => RecoveryContent(
      title: l10n.recoverySessionTitle,
      message: l10n.recoverySessionMessage,
    ),
    OperationalFailureKind.networkUnavailable => RecoveryContent(
      title: l10n.recoveryNetworkTitle,
      message: l10n.recoveryNetworkMessage,
    ),
    OperationalFailureKind.synchronizationPending => RecoveryContent(
      title: l10n.recoverySyncTitle,
      message: l10n.recoverySyncMessage,
    ),
    OperationalFailureKind.batteryLow => RecoveryContent(
      title: l10n.recoveryBatteryTitle,
      message: l10n.recoveryBatteryMessage,
    ),
    OperationalFailureKind.thermalPressure => RecoveryContent(
      title: l10n.recoveryThermalTitle,
      message: l10n.recoveryThermalMessage,
    ),
    OperationalFailureKind.unexpected => RecoveryContent(
      title: l10n.recoveryUnexpectedTitle,
      message: l10n.recoveryUnexpectedMessage,
    ),
  };

  static String actionLabel(
    AppLocalizations l10n,
    OperationalRecoveryAction action,
  ) => switch (action) {
    OperationalRecoveryAction.retry => l10n.tryAgain,
    OperationalRecoveryAction.openDeviceSettings => l10n.cameraOpenSettings,
    OperationalRecoveryAction.openFeedbackSettings => l10n.openFeedbackSettings,
    OperationalRecoveryAction.continueOffline => l10n.recoveryContinueOffline,
    OperationalRecoveryAction.returnToSafety => l10n.recoveryReturnHome,
  };
}
