import 'dart:async';

import 'package:eyes_mobile/app/app.dart';
import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:eyes_mobile/core/error/app_error_reporter.dart';
import 'package:eyes_mobile/core/error/global_error_view.dart';
import 'package:eyes_mobile/core/logging/secure_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> bootstrap(AppEnvironment environment) async {
  WidgetsFlutterBinding.ensureInitialized();

  final logger = SecureLogger(environment)..initialize();
  final errorReporter = AppErrorReporter(logger);

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    errorReporter.captureFlutterError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    errorReporter.capture(error, stackTrace, source: 'platform-dispatcher');
    return true;
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    errorReporter.captureFlutterError(details);
    return const GlobalErrorView();
  };

  await runZonedGuarded<Future<void>>(
    () async {
      runApp(
        ProviderScope(
          overrides: [
            appEnvironmentProvider.overrideWithValue(environment),
            secureLoggerProvider.overrideWithValue(logger),
            appErrorReporterProvider.overrideWithValue(errorReporter),
          ],
          child: const EyesApp(),
        ),
      );
    },
    (Object error, StackTrace stackTrace) {
      errorReporter.capture(error, stackTrace, source: 'root-zone');
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(
          FlutterErrorDetails(exception: error, stack: stackTrace),
        );
      }
    },
  );
}
