import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:eyes_mobile/features/account/domain/scan_metadata.dart';
import 'package:eyes_mobile/features/account/infrastructure/dio_scan_metadata_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_account.dart';
import '../../support/scan_metadata_fixture.dart';

const remoteId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

final class MetadataAdapter implements HttpClientAdapter {
  MetadataAdapter(this.session);
  final ScanMetadata session;
  final requests = <RequestOptions>[];
  final batches = <List<dynamic>>[];
  final stored = <String, Map<String, dynamic>>{};
  String? invalid;
  int? failStatus;
  int deletionStatus = 204;
  bool finished = false;

  Map<String, dynamic> receipt() => {
    'id': remoteId,
    'clientSessionId': session.id,
    'startedAt': session.startedAt.toIso8601String(),
    'endedAt': finished ? session.endedAt.toIso8601String() : null,
    'expiresAt': session.startedAt
        .add(const Duration(days: 30))
        .toIso8601String(),
    'modelId': session.modelId,
    'modelVersion': session.modelVersion,
    'metrics': finished ? session.metrics : null,
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    requests.add(options);
    if (options.method == 'DELETE') {
      return ResponseBody.fromString('', deletionStatus);
    }
    if (failStatus != null) {
      return ResponseBody.fromString(
        '{}',
        failStatus!,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    final data = options.data == null
        ? null
        : Map<String, dynamic>.from(options.data as Map);
    Map<String, dynamic> body;
    if (options.path.endsWith('/events')) {
      final events = data!['events'] as List;
      batches.add(events);
      for (final event in events.cast<Map<String, dynamic>>()) {
        final id = event['clientEventId'] as String;
        expect(
          stored[id] == null || jsonEncode(stored[id]) == jsonEncode(event),
          isTrue,
        );
        stored[id] = event;
      }
      body = {'sessionId': remoteId, 'storedEvents': stored.length};
      if (invalid == 'eventOwner') body['sessionId'] = 'foreign';
      if (invalid == 'eventCount') body['storedEvents'] = 201;
    } else {
      if (options.path.endsWith('/finish')) finished = true;
      body = receipt();
      if (invalid == 'client') body['clientSessionId'] = 'foreign';
      if (invalid == 'id') body['id'] = 'unsafe/path';
      if (invalid == 'model') body['modelId'] = 'wrong';
      if (invalid == 'ttl') body['expiresAt'] = 'invalid';
      if (invalid == 'start') body['startedAt'] = 'invalid';
      if (invalid == 'finish' && finished) body['endedAt'] = null;
      if (invalid == 'metrics' && finished) body['metrics'] = <String, int>{};
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  for (final status in [204, 200]) {
    test('deletion requires an exact 204 receipt: $status', () async {
      final adapter = MetadataAdapter(metadataFixture())
        ..deletionStatus = status;
      final dio = Dio()..httpClientAdapter = adapter;
      final operation = DioScanMetadataGateway(
        dio,
      ).deleteHistory(testRemoteSession, CancelToken());
      if (status == 204) {
        await operation;
      } else {
        await expectLater(operation, throwsFormatException);
      }
      expect(adapter.requests.single.method, 'DELETE');
    });
  }

  test('cancellation before start never sends a request', () async {
    final session = metadataFixture();
    final adapter = MetadataAdapter(session);
    final dio = Dio()..httpClientAdapter = adapter;
    final cancellation = CancelToken()..cancel();
    await expectLater(
      DioScanMetadataGateway(
        dio,
      ).upload(session, testRemoteSession, cancellation),
      throwsA(isA<DioException>()),
    );
    expect(adapter.requests, isEmpty);
  });

  test(
    'batches 200 events as 50 each and replays unchanged after finish',
    () async {
      final session = metadataFixture(events: 200);
      final adapter = MetadataAdapter(session);
      final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
        ..httpClientAdapter = adapter;
      final gateway = DioScanMetadataGateway(dio);
      await gateway.upload(session, testRemoteSession, CancelToken());
      await gateway.upload(session, testRemoteSession, CancelToken());
      expect(adapter.stored, hasLength(200));
      expect(adapter.batches.map((b) => b.length), List.filled(8, 50));
      expect(adapter.requests.map((r) => r.path), [
        for (var i = 0; i < 2; i++) ...[
          '/api/v1/scan-sessions',
          for (var b = 0; b < 4; b++) '/api/v1/scan-sessions/$remoteId/events',
          '/api/v1/scan-sessions/$remoteId/finish',
        ],
      ]);
      for (final request in adapter.requests) {
        expect(
          request.headers['Authorization'],
          'Bearer ${testRemoteSession.accessToken}',
        );
        expect(request.extra['redactedPath'], DioScanMetadataGateway.base);
        expect(request.extra['skipAuthentication'], isTrue);
        expect(utf8.encode(jsonEncode(request.data)).length, lessThan(65536));
        expect(request.data, isNot(contains('ownerId')));
      }
    },
  );

  test(
    'zero events bypasses empty batch and finishes with zero TTS counts',
    () async {
      final session = metadataFixture(events: 0);
      final adapter = MetadataAdapter(session);
      final dio = Dio()..httpClientAdapter = adapter;
      await DioScanMetadataGateway(
        dio,
      ).upload(session, testRemoteSession, CancelToken());
      expect(adapter.requests, hasLength(2));
      expect(adapter.batches, isEmpty);
    },
  );

  for (final invalid in [
    'client',
    'id',
    'model',
    'ttl',
    'start',
    'eventOwner',
    'eventCount',
    'finish',
    'metrics',
  ]) {
    test(
      'rejects invalid $invalid receipt before acknowledging session',
      () async {
        final session = metadataFixture();
        final adapter = MetadataAdapter(session)..invalid = invalid;
        final dio = Dio()..httpClientAdapter = adapter;
        await expectLater(
          DioScanMetadataGateway(
            dio,
          ).upload(session, testRemoteSession, CancelToken()),
          throwsFormatException,
        );
      },
    );
  }

  test('owner mismatch never makes a request', () async {
    final session = metadataFixture(owner: 'foreign');
    final adapter = MetadataAdapter(session);
    final dio = Dio()..httpClientAdapter = adapter;
    await expectLater(
      DioScanMetadataGateway(
        dio,
      ).upload(session, testRemoteSession, CancelToken()),
      throwsFormatException,
    );
    expect(adapter.requests, isEmpty);
  });

  test('partial HTTP failure never sends finish', () async {
    final session = metadataFixture();
    final adapter = MetadataAdapter(session)..failStatus = 500;
    final dio = Dio()..httpClientAdapter = adapter;
    await expectLater(
      DioScanMetadataGateway(
        dio,
      ).upload(session, testRemoteSession, CancelToken()),
      throwsA(isA<DioException>()),
    );
    expect(adapter.finished, isFalse);
  });
}
