import 'dart:io';

import 'package:eyes_mobile/app/app.dart';
import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:eyes_mobile/core/error/app_error_reporter.dart';
import 'package:eyes_mobile/core/logging/secure_logger.dart';
import 'package:eyes_mobile/features/onboarding/application/onboarding_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_onboarding.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final iconBytes = await File(
      'test/fixtures/fonts/MaterialIcons-Regular.otf',
    ).readAsBytes();
    await Future.wait(<Future<void>>[
      (FontLoader('MaterialIcons')
            ..addFont(Future<ByteData>.value(ByteData.sublistView(iconBytes))))
          .load(),
      (FontLoader(
        'Lexend',
      )..addFont(rootBundle.load('assets/fonts/Lexend-Variable.ttf'))).load(),
      (FontLoader('Atkinson Hyperlegible')..addFont(
            rootBundle.load('assets/fonts/AtkinsonHyperlegible-Regular.ttf'),
          ))
          .load(),
      (FontLoader('Atkinson Hyperlegible')..addFont(
            rootBundle.load('assets/fonts/AtkinsonHyperlegible-Bold.ttf'),
          ))
          .load(),
    ]);
  });

  testWidgets('home keeps its visual hierarchy on a compact phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final environment = AppEnvironment.dev();
    final logger = SecureLogger(environment);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appEnvironmentProvider.overrideWithValue(environment),
          secureLoggerProvider.overrideWithValue(logger),
          appErrorReporterProvider.overrideWithValue(AppErrorReporter(logger)),
          onboardingRepositoryProvider.overrideWithValue(
            InMemoryOnboardingRepository(completed: true),
          ),
        ],
        child: const EyesApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Abrir câmera'), findsOneWidget);
    expect(find.text('Configurações de áudio e alertas'), findsOneWidget);
    if (Platform.isWindows) {
      await expectLater(
        find.byType(EyesApp),
        matchesGoldenFile('goldens/windows/home-compact-light.png'),
      );
    }
  });
}
