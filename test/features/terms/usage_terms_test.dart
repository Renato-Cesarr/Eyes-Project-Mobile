import 'package:eyes_mobile/app/app.dart';
import 'package:eyes_mobile/app/routing/app_router.dart';
import 'package:eyes_mobile/core/persistence/storage_providers.dart';
import 'package:eyes_mobile/features/diagnostics/application/diagnostic_ports.dart';
import 'package:eyes_mobile/features/diagnostics/application/diagnostic_recorder.dart';
import 'package:eyes_mobile/features/onboarding/application/onboarding_repository.dart';
import 'package:eyes_mobile/features/scanning/application/camera_gateway.dart';
import 'package:eyes_mobile/features/terms/application/usage_terms.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../support/fake_onboarding.dart';
import '../diagnostics/diagnostics_test.dart' show IdleCamera, MemoryStore;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test(
    'persists the current version locally and rejects older versions',
    () async {
      final preferences = SharedPreferencesAsync();
      final terms = UsageTerms(preferences);
      expect(await terms.isAccepted(), isFalse);
      await terms.accept();
      expect(await UsageTerms(SharedPreferencesAsync()).isAccepted(), isTrue);
      final keys = await preferences.getKeys();
      expect(keys, hasLength(1));
      await preferences.setInt(keys.single, UsageTerms.version - 1);
      expect(await terms.isAccepted(), isFalse);
    },
  );

  testWidgets(
    'requires explicit acceptance even when opening the camera route',
    (tester) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(SharedPreferencesAsync()),
          onboardingRepositoryProvider.overrideWithValue(
            InMemoryOnboardingRepository(completed: true),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const EyesApp()),
      );
      await tester.pumpAndSettle();
      final router = container.read(appRouterProvider);
      router.goNamed(AppRoutes.camera);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/terms');
      final decline = find.text('Não aceitar');
      await tester.ensureVisible(decline);
      await tester.tap(decline);
      await tester.pumpAndSettle();
      expect(await container.read(usageTermsProvider).isAccepted(), isFalse);
      await tester.ensureVisible(find.text('Revisar termo'));
      await tester.tap(find.text('Revisar termo'));
      await tester.pumpAndSettle();
      final accept = find.text('Aceitar e continuar');
      await tester.ensureVisible(accept);
      await tester.tap(accept);
      await tester.pumpAndSettle();
      expect(await container.read(usageTermsProvider).isAccepted(), isTrue);
      expect(router.routeInformationProvider.value.uri.path, '/');
      router.goNamed(AppRoutes.help);
      await tester.pumpAndSettle();
      final review = find.text('Termo de uso e privacidade');
      await tester.ensureVisible(review);
      await tester.tap(review);
      await tester.pumpAndSettle();
      expect(find.text('Sua escolha e consulta'), findsOneWidget);
      expect(accept, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('diagnostics requires terms and keeps separate consent', (
    tester,
  ) async {
    final store = MemoryStore();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(SharedPreferencesAsync()),
        onboardingRepositoryProvider.overrideWithValue(
          InMemoryOnboardingRepository(completed: true),
        ),
        diagnosticsEnabledProvider.overrideWithValue(true),
        diagnosticStoreProvider.overrideWithValue(store),
        cameraGatewayProvider.overrideWithValue(IdleCamera()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const EyesApp()),
    );
    await tester.pumpAndSettle();

    final router = container.read(appRouterProvider);
    router.goNamed(AppRoutes.diagnostics);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/terms');

    final accept = find.text('Aceitar e continuar');
    await tester.ensureVisible(accept);
    await tester.tap(accept);
    await tester.pumpAndSettle();
    router.goNamed(AppRoutes.help);
    await tester.pumpAndSettle();
    final diagnostics = find.text('Diagnóstico de teste');
    await tester.ensureVisible(diagnostics);
    await tester.tap(diagnostics);
    await tester.pumpAndSettle();

    expect(find.text('Nenhum diagnóstico ativo.'), findsOneWidget);
    expect(store.value, isNull);
  });
}
