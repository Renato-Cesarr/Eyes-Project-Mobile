import 'package:eyes_mobile/features/calibration/domain/calibration_configuration.dart';
import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_models.dart';
import 'package:flutter/services.dart';

final class CalibrationConfigurationException implements Exception {
  const CalibrationConfigurationException(this.technicalCode);

  final String technicalCode;
}

final class PlatformCalibrationConfigurationSource {
  const PlatformCalibrationConfigurationSource([
    this._channel = const MethodChannel(_channelName),
    this.platformLookupEnabled = true,
  ]);

  static const _channelName = 'br.com.eyesproject.mobile/calibration';
  static const _nativeRegistrationAttempts = 4;
  static const _nativeRegistrationRetryDelay = Duration(milliseconds: 50);

  final MethodChannel _channel;
  final bool platformLookupEnabled;

  Future<CalibrationConfiguration> load() async {
    if (!platformLookupEnabled) {
      return const CalibrationConfiguration.disabled();
    }
    final raw = await _loadNativeConfiguration();
    if (raw == null || raw['enabled'] != true) {
      return const CalibrationConfiguration.disabled();
    }
    try {
      return CalibrationConfiguration.enabled(
        sessionId: _requiredString(raw, 'sessionId'),
        scenarioId: _requiredString(raw, 'scenarioId'),
        datasetSplit: _parseEnum(
          CalibrationDatasetSplit.values,
          _requiredString(raw, 'datasetSplit'),
        ),
        expectedKind: _parseEnum(
          DetectedObjectKind.values,
          _requiredString(raw, 'expectedKind'),
        ),
        expectedBand: _parseEnum(
          ProximityBand.values,
          _requiredString(raw, 'expectedBand'),
        ),
        lighting: _parseEnum(
          CalibrationLighting.values,
          _requiredString(raw, 'lighting'),
        ),
        occlusion: _parseEnum(
          CalibrationOcclusion.values,
          _requiredString(raw, 'occlusion'),
        ),
      );
    } on Object {
      throw const CalibrationConfigurationException(
        'invalid-calibration-configuration',
      );
    }
  }

  Future<Map<String, Object?>?> _loadNativeConfiguration() async {
    for (var attempt = 1; attempt <= _nativeRegistrationAttempts; attempt++) {
      try {
        return await _channel.invokeMapMethod<String, Object?>(
          'getSessionConfiguration',
        );
      } on MissingPluginException {
        if (attempt == _nativeRegistrationAttempts) {
          rethrow;
        }
        await Future<void>.delayed(_nativeRegistrationRetryDelay);
      }
    }
    return null;
  }

  String _requiredString(Map<String, Object?> raw, String key) {
    final value = raw[key];
    if (value is! String || value.trim().isEmpty) {
      throw CalibrationConfigurationException('missing-$key');
    }
    return value.trim();
  }

  T _parseEnum<T extends Enum>(List<T> values, String name) {
    return values.firstWhere(
      (candidate) => candidate.name == name,
      orElse: () =>
          throw CalibrationConfigurationException('invalid-${T.toString()}'),
    );
  }
}
