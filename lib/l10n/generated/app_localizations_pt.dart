// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Eyes';

  @override
  String get homeTitle => 'Assistência visual ao seu alcance';

  @override
  String get foundationReady =>
      'A fundação do aplicativo está pronta para receber as funcionalidades do MVP.';

  @override
  String get accessibilityDescription =>
      'Este aplicativo respeita o tamanho de fonte do sistema, oferece alto contraste e foi estruturado para funcionar com o TalkBack.';

  @override
  String get testFeedbackLabel => 'Testar vibração e som';

  @override
  String get testFeedbackHint =>
      'Ativa uma confirmação tátil e sonora do aparelho';

  @override
  String get feedbackConfirmed => 'Feedback tátil e sonoro confirmado.';

  @override
  String get feedbackUnavailable =>
      'Não foi possível reproduzir o feedback neste aparelho.';

  @override
  String get loading => 'Carregando';

  @override
  String get unexpectedError => 'Ocorreu um erro inesperado.';

  @override
  String get tryAgain => 'Tentar novamente';

  @override
  String get notFoundTitle => 'Tela não encontrada';

  @override
  String get notFoundMessage => 'Não foi possível encontrar a tela solicitada.';

  @override
  String get goHome => 'Voltar ao início';

  @override
  String get openCamera => 'Abrir câmera';

  @override
  String get cameraPageTitle => 'Câmera e varredura';

  @override
  String get cameraPrivacyNotice =>
      'A imagem é processada apenas enquanto esta tela está ativa. O aplicativo não salva fotos nem vídeos.';

  @override
  String get scanStatusLabel => 'Estado da varredura';

  @override
  String get visionPreparing => 'Preparando inteligência artificial.';

  @override
  String get visionRecovering => 'Recuperando a inteligência artificial.';

  @override
  String get visionReady =>
      'Inteligência artificial pronta. Inicie a câmera quando desejar.';

  @override
  String get visionPaused => 'Varredura pausada e recursos liberados.';

  @override
  String get visionFailed => 'Erro ao iniciar inteligência artificial.';

  @override
  String get visionFailedHelp =>
      'A varredura não foi iniciada. Tente preparar a inteligência artificial novamente.';

  @override
  String get visionRetry => 'Tentar iniciar inteligência artificial novamente';

  @override
  String get scanReady => 'Câmera pronta. Varredura assistiva ativa.';

  @override
  String get detectedPerson => 'Pessoa detectada.';

  @override
  String get detectedChair => 'Cadeira detectada.';

  @override
  String get detectedTable => 'Mesa detectada.';

  @override
  String get detectedBackpack => 'Mochila detectada.';

  @override
  String get cameraStatusLabel => 'Estado da câmera';

  @override
  String get cameraStart => 'Iniciar câmera';

  @override
  String get cameraPause => 'Pausar câmera';

  @override
  String get cameraResume => 'Retomar câmera';

  @override
  String get cameraStop => 'Encerrar câmera';

  @override
  String get cameraPreparing => 'Preparando câmera';

  @override
  String get visionPreparingAction => 'Preparando inteligência artificial';

  @override
  String get cameraOpenSettings => 'Abrir configurações do aparelho';

  @override
  String get cameraUnexpectedError =>
      'Não foi possível carregar o controle da câmera.';

  @override
  String get cameraStatusIdle => 'Pronta para iniciar.';

  @override
  String get cameraStatusRequestingPermission =>
      'Aguardando permissão para usar a câmera.';

  @override
  String get cameraStatusPreparing => 'Preparando a câmera.';

  @override
  String get cameraStatusStreaming => 'Câmera ativa e recebendo imagens.';

  @override
  String get cameraStatusPaused => 'Câmera pausada e recursos liberados.';

  @override
  String get cameraStatusDenied => 'Permissão de câmera negada.';

  @override
  String get cameraStatusPermanentlyDenied =>
      'Permissão de câmera bloqueada nas configurações.';

  @override
  String get cameraStatusBusy =>
      'A câmera está sendo usada por outro aplicativo.';

  @override
  String get cameraStatusUnavailable => 'Câmera indisponível.';

  @override
  String get cameraPermissionDeniedHelp =>
      'Autorize a câmera para iniciar a varredura. Você pode tentar novamente.';

  @override
  String get cameraPermissionPermanentlyDeniedHelp =>
      'Abra as configurações do aparelho e permita o acesso à câmera para o Eyes.';

  @override
  String get cameraPermissionRestrictedHelp =>
      'Este aparelho ou perfil restringe o acesso à câmera.';

  @override
  String get cameraBusyHelp =>
      'Feche outros aplicativos que estejam usando a câmera e tente novamente.';

  @override
  String get cameraMissingHelp =>
      'Nenhuma câmera compatível foi encontrada neste aparelho.';

  @override
  String get cameraTimeoutHelp =>
      'A câmera demorou mais que o esperado para iniciar. Tente novamente.';

  @override
  String get cameraInitializationHelp =>
      'Não foi possível preparar a câmera. Verifique o aparelho e tente novamente.';

  @override
  String get cameraStreamHelp =>
      'A câmera parou de fornecer imagens. Tente iniciar novamente.';

  @override
  String cameraTelemetry(
    String fps,
    int received,
    int processed,
    int dropped,
    int processingMs,
  ) {
    return '$fps FPS • recebidos: $received • processados: $processed • descartados: $dropped • processamento: $processingMs ms';
  }
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get appName => 'Eyes';

  @override
  String get homeTitle => 'Assistência visual ao seu alcance';

  @override
  String get foundationReady =>
      'A fundação do aplicativo está pronta para receber as funcionalidades do MVP.';

  @override
  String get accessibilityDescription =>
      'Este aplicativo respeita o tamanho de fonte do sistema, oferece alto contraste e foi estruturado para funcionar com o TalkBack.';

  @override
  String get testFeedbackLabel => 'Testar vibração e som';

  @override
  String get testFeedbackHint =>
      'Ativa uma confirmação tátil e sonora do aparelho';

  @override
  String get feedbackConfirmed => 'Feedback tátil e sonoro confirmado.';

  @override
  String get feedbackUnavailable =>
      'Não foi possível reproduzir o feedback neste aparelho.';

  @override
  String get loading => 'Carregando';

  @override
  String get unexpectedError => 'Ocorreu um erro inesperado.';

  @override
  String get tryAgain => 'Tentar novamente';

  @override
  String get notFoundTitle => 'Tela não encontrada';

  @override
  String get notFoundMessage => 'Não foi possível encontrar a tela solicitada.';

  @override
  String get goHome => 'Voltar ao início';

  @override
  String get openCamera => 'Abrir câmera';

  @override
  String get cameraPageTitle => 'Câmera e varredura';

  @override
  String get cameraPrivacyNotice =>
      'A imagem é processada apenas enquanto esta tela está ativa. O aplicativo não salva fotos nem vídeos.';

  @override
  String get scanStatusLabel => 'Estado da varredura';

  @override
  String get visionPreparing => 'Preparando inteligência artificial.';

  @override
  String get visionRecovering => 'Recuperando a inteligência artificial.';

  @override
  String get visionReady =>
      'Inteligência artificial pronta. Inicie a câmera quando desejar.';

  @override
  String get visionPaused => 'Varredura pausada e recursos liberados.';

  @override
  String get visionFailed => 'Erro ao iniciar inteligência artificial.';

  @override
  String get visionFailedHelp =>
      'A varredura não foi iniciada. Tente preparar a inteligência artificial novamente.';

  @override
  String get visionRetry => 'Tentar iniciar inteligência artificial novamente';

  @override
  String get scanReady => 'Câmera pronta. Varredura assistiva ativa.';

  @override
  String get detectedPerson => 'Pessoa detectada.';

  @override
  String get detectedChair => 'Cadeira detectada.';

  @override
  String get detectedTable => 'Mesa detectada.';

  @override
  String get detectedBackpack => 'Mochila detectada.';

  @override
  String get cameraStatusLabel => 'Estado da câmera';

  @override
  String get cameraStart => 'Iniciar câmera';

  @override
  String get cameraPause => 'Pausar câmera';

  @override
  String get cameraResume => 'Retomar câmera';

  @override
  String get cameraStop => 'Encerrar câmera';

  @override
  String get cameraPreparing => 'Preparando câmera';

  @override
  String get visionPreparingAction => 'Preparando inteligência artificial';

  @override
  String get cameraOpenSettings => 'Abrir configurações do aparelho';

  @override
  String get cameraUnexpectedError =>
      'Não foi possível carregar o controle da câmera.';

  @override
  String get cameraStatusIdle => 'Pronta para iniciar.';

  @override
  String get cameraStatusRequestingPermission =>
      'Aguardando permissão para usar a câmera.';

  @override
  String get cameraStatusPreparing => 'Preparando a câmera.';

  @override
  String get cameraStatusStreaming => 'Câmera ativa e recebendo imagens.';

  @override
  String get cameraStatusPaused => 'Câmera pausada e recursos liberados.';

  @override
  String get cameraStatusDenied => 'Permissão de câmera negada.';

  @override
  String get cameraStatusPermanentlyDenied =>
      'Permissão de câmera bloqueada nas configurações.';

  @override
  String get cameraStatusBusy =>
      'A câmera está sendo usada por outro aplicativo.';

  @override
  String get cameraStatusUnavailable => 'Câmera indisponível.';

  @override
  String get cameraPermissionDeniedHelp =>
      'Autorize a câmera para iniciar a varredura. Você pode tentar novamente.';

  @override
  String get cameraPermissionPermanentlyDeniedHelp =>
      'Abra as configurações do aparelho e permita o acesso à câmera para o Eyes.';

  @override
  String get cameraPermissionRestrictedHelp =>
      'Este aparelho ou perfil restringe o acesso à câmera.';

  @override
  String get cameraBusyHelp =>
      'Feche outros aplicativos que estejam usando a câmera e tente novamente.';

  @override
  String get cameraMissingHelp =>
      'Nenhuma câmera compatível foi encontrada neste aparelho.';

  @override
  String get cameraTimeoutHelp =>
      'A câmera demorou mais que o esperado para iniciar. Tente novamente.';

  @override
  String get cameraInitializationHelp =>
      'Não foi possível preparar a câmera. Verifique o aparelho e tente novamente.';

  @override
  String get cameraStreamHelp =>
      'A câmera parou de fornecer imagens. Tente iniciar novamente.';

  @override
  String cameraTelemetry(
    String fps,
    int received,
    int processed,
    int dropped,
    int processingMs,
  ) {
    return '$fps FPS • recebidos: $received • processados: $processed • descartados: $dropped • processamento: $processingMs ms';
  }
}
