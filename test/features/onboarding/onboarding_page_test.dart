import 'package:eyes_mobile/app/app.dart';
import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:eyes_mobile/app/routing/app_router.dart';
import 'package:eyes_mobile/core/error/app_error_reporter.dart';
import 'package:eyes_mobile/core/logging/secure_logger.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/assistive_feedback_controller.dart';
import 'package:eyes_mobile/features/onboarding/application/onboarding_repository.dart';
import 'package:eyes_mobile/features/scanning/application/camera_configuration.dart';
import 'package:eyes_mobile/features/scanning/application/camera_gateway.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_permission_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_assistive_feedback.dart';
import '../../support/fake_onboarding.dart';

final class _OnboardingCameraGateway implements CameraGateway {
  _OnboardingCameraGateway({this.permission = CameraPermissionState.granted});

  CameraPermissionState permission;
  int checkCalls = 0;
  int requestCalls = 0;
  int openSettingsCalls = 0;

  @override
  bool get isPreviewReady => false;

  @override
  double? get previewAspectRatio => null;

  @override
  Future<CameraPermissionState> checkPermission() async {
    checkCalls++;
    return permission;
  }

  @override
  Future<void> initialize(CameraConfiguration configuration) async {}

  @override
  Future<bool> openSettings() async {
    openSettingsCalls++;
    return true;
  }

  @override
  Future<void> release() async {}

  @override
  Future<CameraPermissionState> requestPermission() async {
    requestCalls++;
    return permission;
  }

  @override
  Future<void> startStream({
    required CameraFrameHandler onFrame,
    required CameraTelemetryHandler onTelemetry,
    required CameraErrorHandler onError,
  }) async {}
}

void main() {
  testWidgets('completes first use offline without requesting early camera', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryOnboardingRepository();
    final camera = _OnboardingCameraGateway();
    final speech = FakeSpeechGateway();
    final haptics = FakeAssistiveHaptics();
    final semantics = tester.ensureSemantics();
    await _pumpApp(
      tester,
      repository: repository,
      camera: camera,
      speech: speech,
      haptics: haptics,
    );

    expect(find.text('Bem-vindo ao Eyes'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 1 de 5'), findsOneWidget);
    expect(camera.requestCalls, 0);

    await _advance(tester);
    expect(find.text('Use como apoio complementar'), findsOneWidget);
    expect(find.textContaining('não substitui bengala'), findsOneWidget);
    expect(camera.requestCalls, 0);

    await _advance(tester);
    expect(find.text('Suas imagens permanecem no aparelho'), findsOneWidget);
    expect(
      find.textContaining('opera sem internet e sem conta'),
      findsOneWidget,
    );

    await _advance(tester);
    expect(find.text('Prepare voz e vibração'), findsOneWidget);
    await tester.tap(find.text('Testar voz'));
    await tester.pumpAndSettle();
    expect(speech.spoken, contains('Teste de voz do Eyes concluído.'));
    expect(find.text('Teste de voz concluído.'), findsOneWidget);
    await tester.tap(find.text('Testar vibração'));
    await tester.pumpAndSettle();
    expect(haptics.confirmations, 1);
    expect(find.text('Teste de vibração concluído.'), findsOneWidget);

    await _advance(tester);
    expect(find.text('Permita a câmera quando estiver pronto'), findsOneWidget);
    expect(camera.requestCalls, 0);
    await tester.tap(find.text('Permitir acesso à câmera'));
    await tester.pumpAndSettle();

    expect(camera.requestCalls, 1);
    expect(
      find.text(
        'Câmera autorizada. O modo assistivo está pronto para iniciar.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Continuar sem conta no modo offline'));
    await tester.pumpAndSettle();

    expect(repository.completed, isTrue);
    expect(repository.completionWrites, 1);
    expect(find.text('Assistência visual ao seu alcance'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('permanent denial offers settings and a safe offline exit', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryOnboardingRepository();
    final camera = _OnboardingCameraGateway(
      permission: CameraPermissionState.permanentlyDenied,
    );
    await _pumpApp(tester, repository: repository, camera: camera);
    await _goToCameraStep(tester);

    await tester.tap(find.text('Permitir acesso à câmera'));
    await tester.pumpAndSettle();

    expect(find.textContaining('A permissão está bloqueada'), findsOneWidget);
    expect(find.text('Abrir configurações do aparelho'), findsOneWidget);
    expect(find.text('Continuar sem câmera por enquanto'), findsOneWidget);

    await tester.tap(find.text('Abrir configurações do aparelho'));
    await tester.pumpAndSettle();
    expect(camera.openSettingsCalls, 1);

    final continueWithoutCamera = find.text(
      'Continuar sem câmera por enquanto',
    );
    await tester.ensureVisible(continueWithoutCamera);
    await tester.pumpAndSettle();
    await tester.tap(continueWithoutCamera);
    await tester.pumpAndSettle();
    expect(repository.completed, isTrue);
    expect(find.text('Assistência visual ao seu alcance'), findsOneWidget);
  });

  testWidgets('temporary denial can be retried without leaving the flow', (
    WidgetTester tester,
  ) async {
    final camera = _OnboardingCameraGateway(
      permission: CameraPermissionState.denied,
    );
    await _pumpApp(
      tester,
      repository: InMemoryOnboardingRepository(),
      camera: camera,
    );
    await _goToCameraStep(tester);

    await tester.tap(find.text('Permitir acesso à câmera'));
    await tester.pumpAndSettle();
    expect(find.textContaining('A câmera não foi autorizada'), findsOneWidget);
    expect(find.text('Solicitar câmera novamente'), findsOneWidget);

    camera.permission = CameraPermissionState.granted;
    await tester.tap(find.text('Solicitar câmera novamente'));
    await tester.pumpAndSettle();
    expect(camera.requestCalls, 2);
    expect(
      find.text(
        'Câmera autorizada. O modo assistivo está pronto para iniciar.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('completed first use goes directly to the local home', (
    WidgetTester tester,
  ) async {
    final camera = _OnboardingCameraGateway();
    await _pumpApp(
      tester,
      repository: InMemoryOnboardingRepository(completed: true),
      camera: camera,
    );

    expect(find.text('Assistência visual ao seu alcance'), findsOneWidget);
    expect(find.text('Bem-vindo ao Eyes'), findsNothing);
    expect(camera.requestCalls, 0);
  });

  testWidgets('help lets a returning user replay the accessible introduction', (
    WidgetTester tester,
  ) async {
    await _pumpApp(
      tester,
      repository: InMemoryOnboardingRepository(completed: true),
      camera: _OnboardingCameraGateway(),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.text('Assistência visual ao seu alcance')),
    );
    container.read(appRouterProvider).goNamed(AppRoutes.help);
    await tester.pumpAndSettle();

    final repeat = find.text('Repetir primeiros passos');
    await tester.scrollUntilVisible(
      repeat,
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(repeat);
    await tester.pumpAndSettle();

    expect(find.text('Bem-vindo ao Eyes'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 1 de 5'), findsOneWidget);
    expect(find.byTooltip('Fechar'), findsOneWidget);
  });

  testWidgets('all essential actions remain reachable at 200 percent text', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpApp(
      tester,
      repository: InMemoryOnboardingRepository(),
      camera: _OnboardingCameraGateway(),
    );

    for (var index = 0; index < 4; index++) {
      await _advance(tester);
      expect(tester.takeException(), isNull);
    }
    final allow = find.text('Permitir acesso à câmera');
    await tester.ensureVisible(allow);
    await tester.pumpAndSettle();
    expect(allow, findsOneWidget);
    expect(find.text('Voltar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('persistence failure exposes recovery instead of a false home', (
    WidgetTester tester,
  ) async {
    await _pumpApp(
      tester,
      repository: InMemoryOnboardingRepository(
        failure: StateError('storage payload'),
      ),
      camera: _OnboardingCameraGateway(),
    );

    expect(
      find.text(
        'Não foi possível carregar ou salvar os primeiros passos. Tente novamente.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('storage payload'), findsNothing);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required InMemoryOnboardingRepository repository,
  required _OnboardingCameraGateway camera,
  FakeSpeechGateway? speech,
  FakeAssistiveHaptics? haptics,
}) async {
  final environment = AppEnvironment.dev();
  final logger = SecureLogger(environment);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appEnvironmentProvider.overrideWithValue(environment),
        secureLoggerProvider.overrideWithValue(logger),
        appErrorReporterProvider.overrideWithValue(AppErrorReporter(logger)),
        onboardingRepositoryProvider.overrideWithValue(repository),
        cameraGatewayProvider.overrideWithValue(camera),
        speechGatewayProvider.overrideWithValue(speech ?? FakeSpeechGateway()),
        assistiveHapticsProvider.overrideWithValue(
          haptics ?? FakeAssistiveHaptics(),
        ),
        feedbackPreferencesRepositoryProvider.overrideWithValue(
          InMemoryFeedbackPreferencesRepository(),
        ),
      ],
      child: const EyesApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _advance(WidgetTester tester) async {
  final button = find.text('Avançar');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _goToCameraStep(WidgetTester tester) async {
  for (var index = 0; index < 4; index++) {
    await _advance(tester);
  }
}
