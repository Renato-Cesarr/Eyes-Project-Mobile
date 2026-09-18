import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:eyes_mobile/core/network/bearer_session_interceptor.dart';
import 'package:eyes_mobile/core/session/remote_session_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_account.dart';

final class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.statusCode);

  final int statusCode;
  RequestOptions? request;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString('{}', statusCode);
  }
}

void main() {
  test('adds bearer token without exposing it to callers', () async {
    final store = InMemoryRemoteSessionStore(session: testRemoteSession);
    final adapter = _RecordingAdapter(200);
    final dio = Dio()..httpClientAdapter = adapter;
    dio.interceptors.add(BearerSessionInterceptor(store));

    await dio.get<void>('https://example.invalid/private');

    expect(
      adapter.request?.headers['Authorization'],
      'Bearer test-access-token',
    );
    await store.dispose();
  });

  test('skips authentication for login requests', () async {
    final store = InMemoryRemoteSessionStore(session: testRemoteSession);
    final adapter = _RecordingAdapter(200);
    final dio = Dio()..httpClientAdapter = adapter;
    dio.interceptors.add(BearerSessionInterceptor(store));

    await dio.post<void>(
      'https://example.invalid/login',
      options: Options(extra: <String, Object?>{'skipAuthentication': true}),
    );

    expect(adapter.request?.headers['Authorization'], isNull);
    await store.dispose();
  });

  test('401 expires only the remote session', () async {
    final store = InMemoryRemoteSessionStore(session: testRemoteSession);
    final adapter = _RecordingAdapter(401);
    final dio = Dio()..httpClientAdapter = adapter;
    dio.interceptors.add(BearerSessionInterceptor(store));
    final changes = <RemoteSessionChange>[];
    final subscription = store.changes.listen(changes.add);

    await expectLater(
      dio.get<void>('https://example.invalid/private'),
      throwsA(isA<DioException>()),
    );

    expect(store.session, isNull);
    expect(changes.single.reason, RemoteSessionChangeReason.expired);
    await subscription.cancel();
    await store.dispose();
  });
}
