import 'dart:math';

import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:eyes_mobile/features/object_detection/infrastructure/model_contract.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_models.dart';

String metadataUuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

DateTime metadataTime(DateTime value) => DateTime.fromMillisecondsSinceEpoch(
  value.millisecondsSinceEpoch,
  isUtc: true,
);

final class ScanMetadataEvent {
  ScanMetadataEvent({
    required this.id,
    required this.kind,
    required this.confidence,
    required this.band,
    required this.direction,
    required DateTime occurredAt,
  }) : occurredAt = metadataTime(occurredAt) {
    if (!confidence.isFinite ||
        confidence < 0 ||
        confidence > 1 ||
        double.parse(confidence.toStringAsFixed(6)) != confidence) {
      throw const FormatException('Invalid event confidence.');
    }
    _uuid(id);
  }

  factory ScanMetadataEvent.fromJson(Map<String, dynamic> json) =>
      ScanMetadataEvent(
        id: json['clientEventId'] as String,
        kind: _kind(json['objectClass'] as String),
        confidence: (json['confidence'] as num).toDouble(),
        band: ProximityBand.values.byName(json['proximityBand'] as String),
        direction: ProximityDirection.values.byName(
          json['direction'] as String,
        ),
        occurredAt: DateTime.parse(json['occurredAt'] as String),
      );

  final String id;
  final DetectedObjectKind kind;
  final double confidence;
  final ProximityBand band;
  final ProximityDirection direction;
  final DateTime occurredAt;

  Map<String, Object> toJson() => {
    'clientEventId': id,
    'objectClass': kind == DetectedObjectKind.table ? 'table_desk' : kind.name,
    'confidence': confidence,
    'proximityBand': band.name,
    'direction': direction.name,
    'occurredAt': occurredAt.toIso8601String(),
  };
}

/// Closed, immutable session. Owner is local bookkeeping, never sent to the API.
final class ScanMetadata {
  ScanMetadata({
    required this.ownerId,
    required this.id,
    required this.installationId,
    required DateTime startedAt,
    required DateTime endedAt,
    required List<ScanMetadataEvent> events,
    required this.processedFrames,
    required this.inferenceMillisTotal,
    required this.ttsLatencySamples,
    required this.ttsLatencyMillisTotal,
    this.modelId = ModelContract.expectedModelId,
    this.modelVersion = ModelContract.expectedModelVersion,
  }) : startedAt = metadataTime(startedAt),
       endedAt = metadataTime(endedAt),
       events = List.unmodifiable(events) {
    _uuid(id);
    _uuid(installationId);
    if (ownerId.isEmpty ||
        endedAt.isBefore(startedAt) ||
        endedAt.difference(startedAt) > const Duration(hours: 2) ||
        events.length > 200 ||
        events.map((e) => e.id).toSet().length != events.length ||
        events.any(
          (e) =>
              e.occurredAt.isBefore(this.startedAt) ||
              e.occurredAt.isAfter(this.endedAt),
        ) ||
        processedFrames < events.length ||
        processedFrames > 1000000 ||
        inferenceMillisTotal < 0 ||
        inferenceMillisTotal > 1000000000 ||
        ttsLatencySamples < 0 ||
        ttsLatencySamples > events.length ||
        ttsLatencyMillisTotal < 0 ||
        ttsLatencyMillisTotal > 1000000000 ||
        (processedFrames == 0 && inferenceMillisTotal != 0) ||
        (ttsLatencySamples == 0 && ttsLatencyMillisTotal != 0) ||
        !RegExp(r'^[A-Za-z0-9._-]{1,80}$').hasMatch(modelId) ||
        !RegExp(r'^[A-Za-z0-9._-]{1,80}$').hasMatch(modelVersion)) {
      throw const FormatException('Invalid closed session metadata.');
    }
  }

  factory ScanMetadata.fromJson(Map<String, dynamic> json) => ScanMetadata(
    ownerId: json['ownerId'] as String,
    id: json['clientSessionId'] as String,
    installationId: json['installationId'] as String,
    startedAt: DateTime.parse(json['startedAt'] as String),
    endedAt: DateTime.parse(json['endedAt'] as String),
    events: (json['events'] as List)
        .map((e) => ScanMetadataEvent.fromJson(e as Map<String, dynamic>))
        .toList(),
    processedFrames: json['processedFrames'] as int,
    inferenceMillisTotal: json['inferenceMillisTotal'] as int,
    ttsLatencySamples: json['ttsLatencySamples'] as int,
    ttsLatencyMillisTotal: json['ttsLatencyMillisTotal'] as int,
    modelId: json['modelId'] as String,
    modelVersion: json['modelVersion'] as String,
  );

  final String ownerId;
  final String id;
  final String installationId;
  final DateTime startedAt;
  final DateTime endedAt;
  final List<ScanMetadataEvent> events;
  final int processedFrames;
  final int inferenceMillisTotal;
  final int ttsLatencySamples;
  final int ttsLatencyMillisTotal;
  final String modelId;
  final String modelVersion;

  Map<String, Object> get startPayload => {
    'schemaVersion': 1,
    'clientSessionId': id,
    'installationId': installationId,
    'startedAt': startedAt.toIso8601String(),
    'modelId': modelId,
    'modelVersion': modelVersion,
    'consentGranted': true,
    'consentVersion': 'metadata-sync-v1',
  };

  Map<String, int> get metrics => {
    'processedFrames': processedFrames,
    'inferenceMillisTotal': inferenceMillisTotal,
    'ttsLatencySamples': ttsLatencySamples,
    'ttsLatencyMillisTotal': ttsLatencyMillisTotal,
  };

  Map<String, Object> get finishPayload => {
    'endedAt': endedAt.toIso8601String(),
    'metrics': metrics,
  };

  Map<String, Object> toJson() => {
    'ownerId': ownerId,
    'clientSessionId': id,
    'installationId': installationId,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt.toIso8601String(),
    'modelId': modelId,
    'modelVersion': modelVersion,
    'events': events.map((e) => e.toJson()).toList(),
    ...metrics,
  };
}

DetectedObjectKind _kind(String wire) => wire == 'table_desk'
    ? DetectedObjectKind.table
    : DetectedObjectKind.values.byName(wire);

void _uuid(String value) {
  if (!RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value)) {
    throw const FormatException('Invalid metadata UUID.');
  }
}
