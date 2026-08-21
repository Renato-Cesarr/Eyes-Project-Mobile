import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';

final class ProximityClassCalibration {
  const ProximityClassCalibration({
    required this.referenceLinearSize,
    required this.riskWeight,
  });

  /// Expected normalized square-root area when the object is close enough to
  /// occupy a meaningful part of the frame. It is not a metric distance.
  final double referenceLinearSize;
  final double riskWeight;
}

final class ProximityPolicy {
  ProximityPolicy({
    this.iouThreshold = 0.25,
    this.emaAlpha = 0.35,
    this.attentionThreshold = 0.55,
    this.veryNearThreshold = 0.78,
    this.hysteresisMargin = 0.05,
    this.minimumTrackFrames = 3,
    this.transitionConfirmationFrames = 2,
    this.maximumMissedFrames = 3,
    this.globalMinimumInterval = const Duration(seconds: 2),
    this.sameAlertCooldown = const Duration(seconds: 6),
    this.maximumEventHistory = 100,
    this.announceAttention = true,
    Map<DetectedObjectKind, ProximityClassCalibration>? calibrations,
  }) : calibrations =
           Map<DetectedObjectKind, ProximityClassCalibration>.unmodifiable(
             calibrations ?? defaultCalibrations,
           ) {
    if (iouThreshold <= 0 || iouThreshold > 1) {
      throw RangeError.range(iouThreshold, 0, 1, 'iouThreshold');
    }
    if (emaAlpha <= 0 || emaAlpha > 1) {
      throw RangeError.range(emaAlpha, 0, 1, 'emaAlpha');
    }
    if (attentionThreshold <= 0 ||
        veryNearThreshold <= attentionThreshold ||
        veryNearThreshold > 1) {
      throw ArgumentError('Os thresholds de proximidade são inválidos.');
    }
    if (hysteresisMargin <= 0 ||
        attentionThreshold - hysteresisMargin <= 0 ||
        veryNearThreshold + hysteresisMargin > 1) {
      throw ArgumentError('A margem de histerese é inválida.');
    }
    if (minimumTrackFrames < 2 ||
        transitionConfirmationFrames < 2 ||
        maximumMissedFrames < 0 ||
        maximumEventHistory < 1) {
      throw ArgumentError('Os limites temporais da política são inválidos.');
    }
    if (globalMinimumInterval.isNegative || sameAlertCooldown.isNegative) {
      throw ArgumentError('Os intervalos de alerta não podem ser negativos.');
    }
    if (!DetectedObjectKind.values.every(this.calibrations.containsKey)) {
      throw ArgumentError('Toda classe detectável exige calibração.');
    }
    for (final calibration in this.calibrations.values) {
      if (calibration.referenceLinearSize <= 0 ||
          calibration.referenceLinearSize > 1 ||
          calibration.riskWeight < 0 ||
          calibration.riskWeight > 1) {
        throw ArgumentError('A calibração por classe é inválida.');
      }
    }
  }

  static const Map<DetectedObjectKind, ProximityClassCalibration>
  defaultCalibrations = {
    DetectedObjectKind.person: ProximityClassCalibration(
      referenceLinearSize: 0.55,
      riskWeight: 0.60,
    ),
    DetectedObjectKind.chair: ProximityClassCalibration(
      referenceLinearSize: 0.45,
      riskWeight: 1.00,
    ),
    DetectedObjectKind.table: ProximityClassCalibration(
      referenceLinearSize: 0.60,
      riskWeight: 0.90,
    ),
    DetectedObjectKind.backpack: ProximityClassCalibration(
      referenceLinearSize: 0.30,
      riskWeight: 0.75,
    ),
  };

  final double iouThreshold;
  final double emaAlpha;
  final double attentionThreshold;
  final double veryNearThreshold;
  final double hysteresisMargin;
  final int minimumTrackFrames;
  final int transitionConfirmationFrames;
  final int maximumMissedFrames;
  final Duration globalMinimumInterval;
  final Duration sameAlertCooldown;
  final int maximumEventHistory;
  final bool announceAttention;
  final Map<DetectedObjectKind, ProximityClassCalibration> calibrations;
}
