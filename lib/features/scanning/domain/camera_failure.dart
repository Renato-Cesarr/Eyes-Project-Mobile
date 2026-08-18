enum CameraFailureReason {
  permissionDenied,
  permissionPermanentlyDenied,
  permissionRestricted,
  cameraBusy,
  noCamera,
  initializationTimeout,
  initializationFailed,
  streamFailed,
}

final class CameraFailure {
  const CameraFailure({required this.reason, this.technicalCode});

  final CameraFailureReason reason;

  /// A non-sensitive code for diagnostics. Native descriptions are not kept
  /// because they can vary by vendor and are not suitable for end users.
  final String? technicalCode;
}
