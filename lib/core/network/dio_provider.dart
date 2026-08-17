import 'package:dio/dio.dart';
import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:eyes_mobile/core/logging/secure_logger.dart';
import 'package:eyes_mobile/core/network/safe_http_logging_interceptor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<Dio> dioProvider = Provider<Dio>((Ref ref) {
  final environment = ref.watch(appEnvironmentProvider);
  final logger = ref.watch(secureLoggerProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: environment.apiBaseUrl.toString(),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 10),
      headers: const <String, Object>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  )..interceptors.add(SafeHttpLoggingInterceptor(logger));

  ref.onDispose(dio.close);
  return dio;
});
