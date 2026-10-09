import 'package:dio/dio.dart';
import 'package:eyes_mobile/core/session/remote_session.dart';
import 'package:eyes_mobile/features/account/domain/scan_metadata.dart';

abstract interface class ScanMetadataGateway {
  Future<void> upload(
    ScanMetadata metadata,
    RemoteSession account,
    CancelToken cancellation,
  );
  Future<void> deleteHistory(RemoteSession account, CancelToken cancellation);
}

final class DioScanMetadataGateway implements ScanMetadataGateway {
  const DioScanMetadataGateway(this._dio);
  static const base = '/api/v1/scan-sessions';
  final Dio _dio;

  Options _options(RemoteSession account) => Options(
    contentType: Headers.jsonContentType,
    headers: {'Authorization': 'Bearer ${account.accessToken}'},
    extra: {'skipAuthentication': true, 'redactedPath': base},
  );

  @override
  Future<void> upload(
    ScanMetadata metadata,
    RemoteSession account,
    CancelToken cancellation,
  ) async {
    if (metadata.ownerId != account.user.id) {
      throw const FormatException('Session owner mismatch.');
    }
    final response = await _post(
      base,
      data: metadata.startPayload,
      options: _options(account),
      cancelToken: cancellation,
    );
    final start = response.data;
    _validateSession(start, metadata);
    final id = start!['id'] as String;
    if (!RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(id)) {
      throw const FormatException('Invalid remote session receipt.');
    }
    for (var offset = 0; offset < metadata.events.length; offset += 50) {
      final end = (offset + 50).clamp(0, metadata.events.length);
      final batch = await _post(
        '$base/$id/events',
        data: {
          'events': metadata.events
              .sublist(offset, end)
              .map((e) => e.toJson())
              .toList(),
        },
        options: _options(account),
        cancelToken: cancellation,
      );
      if (batch.data?['sessionId'] != id ||
          batch.data?['storedEvents'] is! int ||
          (batch.data!['storedEvents'] as int) < end ||
          (batch.data!['storedEvents'] as int) > metadata.events.length) {
        throw const FormatException('Invalid event receipt.');
      }
    }
    final finish = await _post(
      '$base/$id/finish',
      data: metadata.finishPayload,
      options: _options(account),
      cancelToken: cancellation,
    );
    _validateSession(finish.data, metadata);
    final metrics = finish.data?['metrics'];
    if (finish.data?['id'] != id ||
        !_sameTime(finish.data?['endedAt'], metadata.endedAt) ||
        metrics is! Map ||
        metadata.metrics.entries.any((e) => metrics[e.key] != e.value)) {
      throw const FormatException('Invalid finish receipt.');
    }
  }

  Future<Response<Map<String, dynamic>>> _post(
    String path, {
    required Object data,
    required Options options,
    required CancelToken cancelToken,
  }) async {
    if (cancelToken.isCancelled) throw cancelToken.cancelError!;
    // Drain the current bounded request instead of treating socket cancellation
    // as proof that the server transaction has stopped. Block subsequent batches.
    final receipt = await _dio.post<Map<String, dynamic>>(
      path,
      data: data,
      options: options,
    );
    if (cancelToken.isCancelled) throw cancelToken.cancelError!;
    return receipt;
  }

  @override
  Future<void> deleteHistory(
    RemoteSession account,
    CancelToken cancellation,
  ) async {
    final response = await _dio.delete<void>(
      base,
      options: _options(account),
      cancelToken: cancellation,
    );
    if (response.statusCode != 204) {
      throw const FormatException('Invalid deletion receipt.');
    }
  }

  void _validateSession(Map<String, dynamic>? receipt, ScanMetadata metadata) {
    if (receipt == null ||
        receipt['clientSessionId'] != metadata.id ||
        !_sameTime(receipt['startedAt'], metadata.startedAt) ||
        receipt['modelId'] != metadata.modelId ||
        receipt['modelVersion'] != metadata.modelVersion ||
        receipt['expiresAt'] is! String ||
        DateTime.tryParse(receipt['expiresAt'] as String) !=
            metadata.startedAt.add(const Duration(days: 30))) {
      throw const FormatException('Invalid session receipt.');
    }
  }
}

bool _sameTime(Object? raw, DateTime expected) =>
    raw is String && DateTime.tryParse(raw) == expected;
