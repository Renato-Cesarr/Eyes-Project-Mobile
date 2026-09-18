import 'dart:convert';

final class SyncMetadataRecord {
  SyncMetadataRecord({
    required this.idempotencyKey,
    required this.eventType,
    required this.occurredAt,
    required Map<String, Object?> properties,
  }) : properties = Map<String, Object?>.unmodifiable(properties) {
    if (idempotencyKey.trim().isEmpty || eventType.trim().isEmpty) {
      throw ArgumentError('Metadata identifiers cannot be empty.');
    }
    _validateProperties(this.properties);
  }

  factory SyncMetadataRecord.fromJson(Map<String, Object?> json) {
    final properties = json['properties'];
    if (properties is! Map<String, Object?>) {
      throw const FormatException('Metadata properties are invalid.');
    }
    return SyncMetadataRecord(
      idempotencyKey: json['idempotencyKey']! as String,
      eventType: json['eventType']! as String,
      occurredAt: DateTime.parse(json['occurredAt']! as String).toUtc(),
      properties: properties,
    );
  }

  final String idempotencyKey;
  final String eventType;
  final DateTime occurredAt;
  final Map<String, Object?> properties;

  Map<String, Object?> toJson() => <String, Object?>{
    'idempotencyKey': idempotencyKey,
    'eventType': eventType,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    'properties': properties,
  };

  static void _validateProperties(Map<String, Object?> properties) {
    const forbiddenFragments = <String>{
      'image',
      'photo',
      'video',
      'audio',
      'frame',
      'password',
      'token',
    };
    for (final entry in properties.entries) {
      final normalizedKey = entry.key.toLowerCase();
      if (forbiddenFragments.any(normalizedKey.contains)) {
        throw ArgumentError('Sensitive or media metadata is not allowed.');
      }
      final value = entry.value;
      if (value != null &&
          value is! String &&
          value is! num &&
          value is! bool) {
        throw ArgumentError('Metadata values must be scalar.');
      }
    }
    if (utf8.encode(jsonEncode(properties)).length > 4096) {
      throw ArgumentError('Metadata payload exceeds the local queue limit.');
    }
  }
}
