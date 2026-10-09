import 'package:dio/dio.dart';
import 'package:eyes_mobile/core/session/remote_session.dart';
import 'package:eyes_mobile/features/account/domain/scan_metadata.dart';
import 'package:eyes_mobile/features/account/infrastructure/dio_scan_metadata_gateway.dart';
import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_models.dart';

import 'fake_account.dart';

final metadataStart = DateTime.utc(2026, 10, 9, 12);
const metadataInstallation = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';

ScanMetadata metadataFixture({
  int events = 1,
  String? id,
  String? owner,
  DateTime? start,
}) {
  final time = start ?? metadataStart;
  return ScanMetadata(
    ownerId: owner ?? testRemoteSession.user.id,
    id: id ?? metadataUuid(),
    installationId: metadataInstallation,
    startedAt: time,
    endedAt: time.add(const Duration(minutes: 1)),
    events: List.generate(
      events,
      (i) => ScanMetadataEvent(
        id: metadataUuid(),
        kind: DetectedObjectKind.table,
        confidence: 0.812345,
        band: ProximityBand.veryNear,
        direction: ProximityDirection.ahead,
        occurredAt: time.add(Duration(milliseconds: i + 1)),
      ),
    ),
    processedFrames: events + 10,
    inferenceMillisTotal: 140,
    ttsLatencySamples: events,
    ttsLatencyMillisTotal: events * 30,
  );
}

final class FakeScanMetadataGateway implements ScanMetadataGateway {
  final List<ScanMetadata> sent = [];
  final List<String> owners = [];
  Future<void> Function(ScanMetadata, CancelToken)? onUpload;
  Future<void> Function(CancelToken)? onDelete;
  int deleteCalls = 0;

  @override
  Future<void> upload(
    ScanMetadata data,
    RemoteSession account,
    CancelToken cancel,
  ) async {
    sent.add(data);
    owners.add(account.user.id);
    await onUpload?.call(data, cancel);
  }

  @override
  Future<void> deleteHistory(RemoteSession account, CancelToken cancel) async {
    deleteCalls++;
    await onDelete?.call(cancel);
  }
}

DioException metadataHttpFailure(int? status) {
  final options = RequestOptions(path: '/api/v1/scan-sessions');
  return DioException(
    requestOptions: options,
    type: status == null
        ? DioExceptionType.connectionError
        : DioExceptionType.badResponse,
    response: status == null
        ? null
        : Response<void>(requestOptions: options, statusCode: status),
  );
}
