import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:eyes_mobile/core/session/remote_session.dart';
import 'package:eyes_mobile/features/account/domain/scan_metadata.dart';
import 'package:eyes_mobile/features/account/infrastructure/dio_scan_metadata_gateway.dart';
import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_models.dart';

/// Opt-in HTTP proof using the actual mobile gateway, local API and Mailpit.
/// Creates synthetic accounts; never deletes an existing user's history.
Future<void> main(List<String> arguments) async {
  if (arguments.length != 2) {
    stderr.writeln(
      'Usage: dart run tool/verify_scan_metadata_api.dart LOCAL_ENV REPORT_JSON',
    );
    exitCode = 64;
    return;
  }
  final api = Dio(
    BaseOptions(
      baseUrl: 'http://127.0.0.1:18080',
      contentType: Headers.jsonContentType,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  final mailpit = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8025'));
  try {
    final settings = <String, String>{};
    for (final line in await File(arguments.first).readAsLines()) {
      if (line.startsWith('#') || !line.contains('=')) continue;
      final position = line.indexOf('=');
      settings[line.substring(0, position)] = line.substring(position + 1);
    }
    final administrator = await _login(
      api,
      settings['BOOTSTRAP_ADMIN_EMAIL']!,
      settings['BOOTSTRAP_ADMIN_PASSWORD']!,
    );
    final adminOptions = Options(
      headers: {'Authorization': 'Bearer ${administrator.accessToken}'},
    );
    final before = (await api.get<Map<String, dynamic>>(
      '/api/v1/scan-sessions/aggregate',
      options: adminOptions,
    )).data!;
    final first = await _syntheticAccount(api, mailpit, adminOptions);
    final second = await _syntheticAccount(api, mailpit, adminOptions);
    final firstData = _metadata(first.user.id, 51);
    final secondData = _metadata(second.user.id, 1);
    final gateway = DioScanMetadataGateway(api);
    await gateway.upload(firstData, first, CancelToken());
    await gateway.upload(firstData, first, CancelToken());
    await gateway.upload(secondData, second, CancelToken());
    final after = (await api.get<Map<String, dynamic>>(
      '/api/v1/scan-sessions/aggregate',
      options: adminOptions,
    )).data!;
    _require(
      after['sessions'] == (before['sessions'] as int) + 2,
      'session idempotency',
    );
    _require(
      after['announcedEvents'] == (before['announcedEvents'] as int) + 52,
      'event idempotency',
    );
    final firstReceipt = (await api.post<Map<String, dynamic>>(
      '/api/v1/scan-sessions',
      data: firstData.startPayload,
      options: Options(
        headers: {'Authorization': 'Bearer ${first.accessToken}'},
      ),
    )).data!;
    final secondReceipt = (await api.post<Map<String, dynamic>>(
      '/api/v1/scan-sessions',
      data: secondData.startPayload,
      options: Options(
        headers: {'Authorization': 'Bearer ${second.accessToken}'},
      ),
    )).data!;
    final own = await api.get<Map<String, dynamic>>(
      '/api/v1/scan-sessions/${firstReceipt['id']}',
      options: Options(
        headers: {'Authorization': 'Bearer ${first.accessToken}'},
      ),
    );
    _require(
      (own.data!['metrics'] as Map<String, dynamic>)['ttsLatencySamples'] == 51,
      'finished session receipt',
    );
    final foreign = await api.get<void>(
      '/api/v1/scan-sessions/${firstReceipt['id']}',
      options: Options(
        headers: {'Authorization': 'Bearer ${second.accessToken}'},
        validateStatus: (_) => true,
      ),
    );
    _require(foreign.statusCode == 404, 'foreign session isolation');
    await gateway.deleteHistory(first, CancelToken());
    final deleted = await api.get<void>(
      '/api/v1/scan-sessions/${firstReceipt['id']}',
      options: Options(
        headers: {'Authorization': 'Bearer ${first.accessToken}'},
        validateStatus: (_) => true,
      ),
    );
    _require(deleted.statusCode == 404, 'own history deletion');
    final retained = await api.get<void>(
      '/api/v1/scan-sessions/${secondReceipt['id']}',
      options: Options(
        headers: {'Authorization': 'Bearer ${second.accessToken}'},
      ),
    );
    _require(retained.statusCode == 200, 'other owner preserved');
    await gateway.deleteHistory(second, CancelToken());
    final finalAggregate = (await api.get<Map<String, dynamic>>(
      '/api/v1/scan-sessions/aggregate',
      options: adminOptions,
    )).data!;
    _require(
      jsonEncode(finalAggregate) == jsonEncode(before),
      'synthetic metadata cleanup',
    );
    final report = {
      'verifiedAt': DateTime.now().toUtc().toIso8601String(),
      'success': true,
      'transport':
          'actual mobile Dart Dio gateway -> local Spring API -> PostgreSQL',
      'loginAndInvitation': true,
      'syntheticAccounts': 2,
      'closedSessions': 2,
      'events': 52,
      'largestSessionEvents': 51,
      'replayedSessionWithoutDuplication': true,
      'ownershipIsolation': true,
      'deletionPreservedOtherOwner': true,
      'syntheticMetadataRemoved': true,
      'tokensPasswordsEmailsIncluded': false,
      'deviceCameraAudioOrTalkBackExecuted': false,
      'metricsSource': 'synthetic contract data; not measurements',
    };
    await File(
      arguments.last,
    ).writeAsString('${const JsonEncoder.withIndent('  ').convert(report)}\n');
    stdout.writeln(
      'PASS: real API contract, replay, ownership and scoped deletion; synthetic data only.',
    );
  } on DioException catch (error) {
    stderr.writeln(
      'FAIL: HTTP ${error.response?.statusCode ?? 'network'} ${error.type.name}; sensitive payload omitted.',
    );
    exitCode = 1;
  } on Object catch (error) {
    stderr.writeln('FAIL: ${error.runtimeType}; sensitive payload omitted.');
    exitCode = 1;
  } finally {
    api.close();
    mailpit.close();
  }
}

Future<RemoteSession> _login(Dio api, String email, String password) async {
  final body = (await api.post<Map<String, dynamic>>(
    '/api/v1/auth/login',
    data: {'email': email, 'password': password},
  )).data!;
  return RemoteSession(
    accessToken: body['token'] as String,
    user: RemoteUser.fromJson(body['user'] as Map<String, dynamic>),
  );
}

Future<RemoteSession> _syntheticAccount(
  Dio api,
  Dio mailpit,
  Options admin,
) async {
  final email = 'ren75-${metadataUuid()}@eyes.test';
  await api.post<void>(
    '/api/v1/users',
    data: {'name': 'QA REN-75 synthetic', 'email': email},
    options: admin,
  );
  String? token;
  for (var attempt = 0; attempt < 20 && token == null; attempt++) {
    final messages =
        (await mailpit.get<Map<String, dynamic>>(
              '/api/v1/messages',
            )).data!['messages']
            as List;
    for (final raw in messages.cast<Map<String, dynamic>>()) {
      if (!(raw['To'] as List).any((to) => (to as Map)['Address'] == email)) {
        continue;
      }
      final message = (await mailpit.get<Map<String, dynamic>>(
        '/api/v1/message/${raw['ID']}',
      )).data!;
      final match = RegExp(
        r'setup-password\?token=([A-Za-z0-9-]+)',
      ).firstMatch('${message['Text']} ${message['HTML']}');
      token = match?.group(1);
    }
    if (token == null) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }
  _require(token != null, 'local invitation delivery');
  final random = Random.secure();
  final password = List.generate(
    32,
    (_) => random.nextInt(16).toRadixString(16),
  ).join();
  await api.post<void>(
    '/api/v1/users/setup-password',
    data: {'token': token, 'password': password},
  );
  return _login(api, email, password);
}

ScanMetadata _metadata(String owner, int events) {
  final start = metadataTime(
    DateTime.now().toUtc().subtract(const Duration(seconds: 5)),
  );
  return ScanMetadata(
    ownerId: owner,
    id: metadataUuid(),
    installationId: metadataUuid(),
    startedAt: start,
    endedAt: start.add(const Duration(seconds: 2)),
    events: List.generate(
      events,
      (i) => ScanMetadataEvent(
        id: metadataUuid(),
        kind: DetectedObjectKind.table,
        confidence: 0.812345,
        band: ProximityBand.veryNear,
        direction: ProximityDirection.ahead,
        occurredAt: start.add(Duration(milliseconds: i + 1)),
      ),
    ),
    processedFrames: events + 10,
    inferenceMillisTotal: 100,
    ttsLatencySamples: events,
    ttsLatencyMillisTotal: events * 30,
  );
}

void _require(bool condition, String reason) {
  if (!condition) throw StateError(reason);
}
