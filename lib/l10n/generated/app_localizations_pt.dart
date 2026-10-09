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
  String get accountTitle => 'Conta opcional';

  @override
  String get openAccountSettings => 'Conta opcional';

  @override
  String get onboardingOptionalAccount => 'Configurar conta opcional';

  @override
  String get accountLoading => 'Carregando conta';

  @override
  String get accountLoadError =>
      'Não foi possível carregar a conta. A varredura offline continua disponível.';

  @override
  String get accountOptionalHeading => 'Conta opcional';

  @override
  String get accountConnectedHeading => 'Conta conectada';

  @override
  String get accountOfflineGuarantee =>
      'A câmera e os avisos continuam funcionando localmente, sem conta e sem internet.';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get emailHint => 'nome@exemplo.com';

  @override
  String get emailRequired => 'Informe o e-mail.';

  @override
  String get emailInvalid => 'Informe um e-mail válido.';

  @override
  String get passwordLabel => 'Senha';

  @override
  String get passwordRequired => 'Informe a senha.';

  @override
  String get showPassword => 'Mostrar senha';

  @override
  String get hidePassword => 'Ocultar senha';

  @override
  String get accountSignIn => 'Entrar';

  @override
  String get accountSigningIn => 'Entrando';

  @override
  String get accountContinueOffline => 'Continuar para a varredura offline';

  @override
  String get accountReviewAndRetry => 'Revisar dados e tentar novamente';

  @override
  String get accountSignedIn =>
      'Conta conectada. A varredura offline permanece disponível.';

  @override
  String get accountSignedOut =>
      'Sessão remota encerrada. Seus recursos locais continuam disponíveis.';

  @override
  String get accountSignOut => 'Sair da conta';

  @override
  String get syncConsentLabel => 'Permitir sincronização de metadados';

  @override
  String get syncConsentDescription =>
      'Autorize o envio das próximas sessões após encerrar a varredura. A câmera e a voz continuam funcionando offline.';

  @override
  String get syncMetadataOnlyNotice =>
      'Envia classe do objeto, confiança, proximidade relativa, direção e contadores. Sem imagens, vídeos, áudio ou localização. No servidor, os dados ficam vinculados à sua conta por até 30 dias. Pendentes locais ficam até enviar ou desativar.';

  @override
  String get syncConsentDialogTitle => 'Permitir sincronização?';

  @override
  String get syncConsentDialogMessage =>
      'Você autoriza coletar os metadados das próximas sessões neste aparelho e enviá-los após encerrar a varredura. No servidor, os dados ficam vinculados à sua conta por até 30 dias. Pendentes locais permanecem até enviar ou desativar. Nenhuma imagem, vídeo, áudio ou localização é enviado. Desativar limpa os pendentes deste aparelho; para remover o histórico remoto, use Excluir histórico. Ao autorizar outra conta, os pendentes da conta anterior neste aparelho serão apagados.';

  @override
  String get syncConsentConfirm => 'Permitir';

  @override
  String get syncConsentEnabled => 'Consentimento de sincronização ativado.';

  @override
  String get syncConsentRevoked =>
      'Consentimento revogado e fila local de sincronização apagada.';

  @override
  String get onboardingTitle => 'Primeiros passos';

  @override
  String onboardingProgress(int current, int total) {
    return 'Etapa $current de $total';
  }

  @override
  String get onboardingWelcomeTitle => 'Bem-vindo ao Eyes';

  @override
  String get onboardingWelcomeBody =>
      'O Eyes usa a câmera do celular para reconhecer alguns objetos e oferecer avisos curtos por voz e vibração.';

  @override
  String get onboardingSafetyTitle => 'Use como apoio complementar';

  @override
  String get onboardingSafetyBody =>
      'O Eyes pode errar ou não perceber um obstáculo. Ele não substitui bengala, cão-guia, orientação humana nem técnicas de mobilidade.';

  @override
  String get onboardingPrivacyTitle => 'Suas imagens permanecem no aparelho';

  @override
  String get onboardingPrivacyBody =>
      'A câmera é processada localmente durante a varredura. O Eyes não salva fotos ou vídeos e a função assistiva opera sem internet e sem conta. Nenhum metadado é enviado.';

  @override
  String get onboardingFeedbackTitle => 'Prepare voz e vibração';

  @override
  String get onboardingFeedbackBody =>
      'Teste os dois canais antes de usar. A vibração complementa a voz e nunca é o único aviso.';

  @override
  String get onboardingCameraTitle => 'Permita a câmera quando estiver pronto';

  @override
  String get onboardingCameraBody =>
      'A câmera é necessária somente para a varredura. A solicitação acontece agora, depois desta explicação.';

  @override
  String get onboardingAllowCamera => 'Permitir acesso à câmera';

  @override
  String get onboardingTryCameraAgain => 'Solicitar câmera novamente';

  @override
  String get onboardingCameraGranted =>
      'Câmera autorizada. O modo assistivo está pronto para iniciar.';

  @override
  String get onboardingCameraDenied =>
      'A câmera não foi autorizada. Você pode tentar novamente ou continuar e permitir depois.';

  @override
  String get onboardingCameraPermanentlyDenied =>
      'A permissão está bloqueada. Abra as configurações do aparelho para autorizar a câmera.';

  @override
  String get onboardingCameraRestricted =>
      'Este aparelho ou perfil restringe a câmera. Verifique as configurações ou continue sem a varredura.';

  @override
  String get onboardingContinueOffline => 'Continuar sem conta no modo offline';

  @override
  String get onboardingContinueWithoutCamera =>
      'Continuar sem câmera por enquanto';

  @override
  String get onboardingLoadError =>
      'Não foi possível carregar ou salvar os primeiros passos. Tente novamente.';

  @override
  String get repeatOnboarding => 'Repetir primeiros passos';

  @override
  String get repeatFeedbackTests => 'Repetir testes de voz e vibração';

  @override
  String get next => 'Avançar';

  @override
  String get back => 'Voltar';

  @override
  String get close => 'Fechar';

  @override
  String get homeTitle => 'Reconhecer objetos';

  @override
  String get foundationReady =>
      'Abra a câmera para ouvir o que está à sua frente.';

  @override
  String get homeOfflineTitle => 'Funciona sem internet.';

  @override
  String get homeOfflineMessage =>
      'A câmera e a inteligência artificial processam as imagens neste aparelho. Nenhuma foto ou vídeo é salvo.';

  @override
  String get homeSupportTitle => 'Ajustes e suporte';

  @override
  String get homeSupportDescription =>
      'Personalize os avisos, consulte orientações de segurança ou conecte uma conta opcional.';

  @override
  String get accessibilityDescription =>
      'Este aplicativo respeita o tamanho de fonte do sistema, oferece alto contraste e foi estruturado para funcionar com o TalkBack.';

  @override
  String get testFeedbackLabel => 'Testar som e vibração';

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
  String get cameraPageTitle => 'Câmera';

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
  String get visionFailed => 'Não foi possível iniciar.';

  @override
  String get visionFailedHelp =>
      'A varredura não foi iniciada. Tente novamente.';

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
  String get objectPerson => 'Pessoa';

  @override
  String get objectChair => 'Cadeira';

  @override
  String get objectTable => 'Mesa';

  @override
  String get objectBackpack => 'Mochila';

  @override
  String proximityDistant(String object) {
    return '$object distante.';
  }

  @override
  String proximityAttention(String object) {
    return '$object próxima. Atenção.';
  }

  @override
  String proximityVeryNear(String object) {
    return '$object muito próxima. Cuidado.';
  }

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
  String get recoveryCameraPermissionTitle => 'A câmera precisa de permissão';

  @override
  String get recoveryCameraPermissionBlockedTitle =>
      'Permissão de câmera bloqueada';

  @override
  String get recoveryCameraRestrictedTitle => 'A câmera está restrita';

  @override
  String get recoveryCameraTimeoutTitle => 'A câmera demorou para iniciar';

  @override
  String get recoveryCameraInterruptedTitle => 'A câmera foi interrompida';

  @override
  String get recoveryModelTimeoutTitle =>
      'A inteligência artificial demorou para iniciar';

  @override
  String get recoveryModelTimeoutMessage =>
      'A varredura permaneceu desligada. Tente preparar a inteligência artificial novamente.';

  @override
  String get recoveryModelUnavailableTitle => 'Não foi possível iniciar.';

  @override
  String get recoveryModelInvalidMessage =>
      'O recurso de reconhecimento não pôde ser validado. Tente novamente ou volte ao início com segurança.';

  @override
  String get recoveryModelMemoryMessage =>
      'Faltou memória para iniciar. Feche outros aplicativos e tente novamente.';

  @override
  String get recoveryModelDelegateMessage =>
      'O acelerador do aparelho não está disponível. Tente novamente usando o processamento compatível.';

  @override
  String get recoverySpeechTitle => 'Avisos por voz indisponíveis';

  @override
  String get recoverySpeechMessage =>
      'A varredura pode continuar, mas os avisos falados podem não funcionar. Verifique as configurações de voz antes de usar.';

  @override
  String get recoveryHapticsTitle => 'Vibração indisponível';

  @override
  String get recoveryHapticsMessage =>
      'A varredura pode continuar com avisos por voz e texto. Verifique as configurações de vibração.';

  @override
  String get recoveryPreferencesTitle => 'Preferências não foram salvas';

  @override
  String get recoveryPreferencesMessage =>
      'Os padrões seguros estão ativos nesta sessão. Revise as configurações quando puder.';

  @override
  String get recoveryLoginTitle => 'Não foi possível entrar';

  @override
  String get recoveryInvalidCredentialsMessage =>
      'Confira os dados informados ou continue usando a varredura offline.';

  @override
  String get recoverySessionTitle => 'Sua sessão terminou';

  @override
  String get recoverySessionMessage =>
      'Entre novamente quando houver conexão. A varredura offline continua disponível.';

  @override
  String get recoveryNetworkTitle => 'Sem conexão com o serviço';

  @override
  String get recoveryNetworkMessage =>
      'A sincronização ficará pendente. A varredura local continua disponível.';

  @override
  String get recoverySyncTitle => 'Sincronização pendente';

  @override
  String get recoverySyncMessage =>
      'Os dados permitidos serão enviados quando a conexão voltar. A varredura local não foi interrompida.';

  @override
  String get recoveryBatteryTitle => 'Bateria baixa';

  @override
  String get recoveryBatteryMessage =>
      'O ritmo da varredura foi reduzido para preservar a bateria.';

  @override
  String get recoveryThermalTitle => 'Aparelho aquecido';

  @override
  String get recoveryThermalMessage =>
      'O ritmo da varredura foi reduzido até o aparelho esfriar.';

  @override
  String get recoveryUnexpectedTitle => 'Não foi possível iniciar a varredura';

  @override
  String get recoveryUnexpectedMessage =>
      'A varredura permaneceu desligada. Tente novamente ou volte ao início com segurança.';

  @override
  String get recoveryContinueOffline => 'Continuar no modo offline';

  @override
  String get recoveryReturnHome => 'Voltar ao início';

  @override
  String get assistiveScanTitle => 'Varredura assistiva';

  @override
  String get openHelpAndSafety => 'Ajuda e segurança';

  @override
  String get scanCapabilitiesTitle => 'Recursos ativos';

  @override
  String get scanAudioAvailable => 'Avisos por voz disponíveis';

  @override
  String get scanAudioUnavailable => 'Avisos por voz indisponíveis';

  @override
  String get scanHapticsAvailable => 'Vibração ativa';

  @override
  String get scanHapticsDisabled => 'Vibração desativada nas configurações';

  @override
  String get scanHapticsUnavailable => 'Vibração indisponível';

  @override
  String get scanOfflineAvailable => 'Varredura offline disponível';

  @override
  String get scanStart => 'Iniciar varredura';

  @override
  String get scanStartHint => 'Ativa a câmera e os avisos de obstáculos';

  @override
  String get scanPause => 'Pausar varredura';

  @override
  String get scanPauseHint =>
      'Interrompe a câmera e libera os recursos do aparelho';

  @override
  String get scanResume => 'Retomar varredura';

  @override
  String get scanResumeHint => 'Reativa a câmera e os avisos de obstáculos';

  @override
  String get scanPreparingHint => 'Aguarde enquanto os recursos são preparados';

  @override
  String get scanEnded =>
      'Varredura encerrada. A câmera e a inteligência artificial estão desligadas.';

  @override
  String get scanStop => 'Encerrar varredura';

  @override
  String get scanStopHint =>
      'Solicita confirmação antes de desligar a varredura';

  @override
  String get scanStopDialogTitle => 'Encerrar a varredura?';

  @override
  String get scanStopDialogMessage =>
      'Você deixará de receber avisos de obstáculos até iniciar uma nova varredura.';

  @override
  String get scanKeepRunning => 'Continuar varredura';

  @override
  String get scanConfirmStop => 'Encerrar agora';

  @override
  String get helpAndSafetyTitle => 'Ajuda e segurança';

  @override
  String get helpAndSafetyIntro =>
      'Orientações para usar a câmera e os avisos com segurança.';

  @override
  String get helpSafetyHeading => 'Uso seguro';

  @override
  String get helpSafetyBody =>
      'O Eyes é um apoio complementar. Ele não substitui bengala, cão-guia, orientação humana nem técnicas de mobilidade.';

  @override
  String get helpPrivacyHeading => 'Privacidade';

  @override
  String get helpPrivacyBody =>
      'As imagens são processadas localmente durante a varredura e não são salvas como foto ou vídeo.';

  @override
  String get helpScanningHeading => 'Como usar a varredura';

  @override
  String get helpScanningBody =>
      'Mantenha a câmera traseira livre. Inicie a varredura e siga os avisos curtos de voz e vibração. Pause ou encerre quando não precisar dos alertas.';

  @override
  String get helpPermissionHeading => 'Permissão da câmera';

  @override
  String get helpPermissionBody =>
      'A câmera é solicitada somente ao iniciar. Se a permissão estiver bloqueada, use a ação para abrir as configurações do aparelho.';

  @override
  String get openFeedbackSettings => 'Áudio e alertas';

  @override
  String get feedbackSettingsTitle => 'Áudio e alertas';

  @override
  String get feedbackSettingsIntro =>
      'Seus ajustes ficam salvos apenas neste aparelho.';

  @override
  String get appearanceSectionTitle => 'Aparência e contraste';

  @override
  String get appearanceSectionDescription =>
      'Escolha uma opção confortável para leitura. O alto contraste reforça bordas e diferenças entre as cores.';

  @override
  String get appearanceLabel => 'Tema do aplicativo';

  @override
  String get appearanceSystem => 'Seguir configuração do aparelho';

  @override
  String get appearanceSystemShort => 'Padrão do aparelho';

  @override
  String get appearanceLight => 'Claro';

  @override
  String get appearanceDark => 'Escuro';

  @override
  String get appearanceHighContrastLight => 'Alto contraste claro';

  @override
  String get appearanceHighContrastDark => 'Alto contraste escuro';

  @override
  String get appearanceSaved => 'Aparência atualizada.';

  @override
  String get appearanceSaveFailed =>
      'Não foi possível salvar a aparência. A configuração anterior foi mantida.';

  @override
  String get loadingFeedbackSettings =>
      'Carregando configurações de áudio e alertas';

  @override
  String get feedbackSettingsLoadError =>
      'Não foi possível carregar as configurações. Tente novamente.';

  @override
  String get voiceSectionTitle => 'Voz';

  @override
  String get speechRateLabel => 'Velocidade da voz';

  @override
  String speechRateValue(int percent) {
    return '$percent por cento';
  }

  @override
  String get speechRateRange =>
      'Ajustável de 30 a 70 por cento. Deslize para cima ou para baixo para alterar.';

  @override
  String get speechVolumeLabel => 'Volume da voz';

  @override
  String percentValue(int percent) {
    return '$percent por cento';
  }

  @override
  String get speechVolumeRange =>
      'Ajustável de zero a 100 por cento. Deslize para cima ou para baixo para alterar.';

  @override
  String get voiceDetailLabel => 'Nível de detalhe';

  @override
  String get voiceDetailConcise => 'Frases curtas';

  @override
  String get voiceDetailDetailed => 'Frases com orientação';

  @override
  String get testVoice => 'Testar voz';

  @override
  String get voiceTestPhrase => 'Teste de voz do Eyes concluído.';

  @override
  String get alertsSectionTitle => 'Alertas';

  @override
  String get announceAttentionLabel => 'Avisar também objetos próximos';

  @override
  String get announceAttentionDescription =>
      'Quando desativado, o Eyes fala apenas sobre objetos muito próximos.';

  @override
  String get sensitivityLabel => 'Frequência dos alertas';

  @override
  String get sensitivityConservative => 'Conservador';

  @override
  String get sensitivityBalanced => 'Equilibrado';

  @override
  String get sensitivityFewerAlerts => 'Menos alertas';

  @override
  String get sensitivityConservativeDescription =>
      'Avisa mais cedo e repete com maior frequência.';

  @override
  String get sensitivityBalancedDescription =>
      'Equilibra segurança e quantidade de avisos.';

  @override
  String get sensitivityFewerAlertsDescription =>
      'Exige mais persistência e aumenta o intervalo entre avisos.';

  @override
  String get hapticsSectionTitle => 'Vibração';

  @override
  String get hapticsEnabledLabel => 'Usar vibração';

  @override
  String get hapticsDescription =>
      'Alertas muito próximos usam duas vibrações curtas como reforço ao áudio.';

  @override
  String get testHaptics => 'Testar vibração';

  @override
  String get privacySectionTitle => 'Privacidade e sincronização';

  @override
  String get feedbackPrivacyDescription =>
      'O reconhecimento e os alertas funcionam localmente, sem enviar imagens. As preferências não contêm dados sensíveis e não são sincronizadas no MVP.';

  @override
  String get restoreDefaults => 'Restaurar configurações padrão';

  @override
  String get restoreDefaultsTitle => 'Restaurar configurações?';

  @override
  String get restoreDefaultsDescription =>
      'Velocidade, volume, alertas e vibração voltarão aos valores recomendados.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirmRestore => 'Restaurar';

  @override
  String get preferencesSaved => 'Configuração salva.';

  @override
  String get defaultsRestored => 'Configurações padrão restauradas.';

  @override
  String get voiceTestSucceeded => 'Teste de voz concluído.';

  @override
  String get hapticTestSucceeded => 'Teste de vibração concluído.';

  @override
  String get speechUnavailable =>
      'A voz está indisponível. Verifique o mecanismo de síntese do aparelho e tente novamente.';

  @override
  String get hapticsUnavailable =>
      'A vibração não está disponível neste aparelho. Os avisos por voz continuam funcionando.';

  @override
  String get preferencesSaveFailed =>
      'Não foi possível salvar a configuração. Tente novamente.';

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

  @override
  String get homeSettingsAction => 'Abrir configurações';

  @override
  String get homePrivacyNote => 'Nenhuma foto ou vídeo é salvo.';

  @override
  String get scanSyncTitle => 'Envio de metadados';

  @override
  String get scanSyncDisabled =>
      'Envio desativado. A assistência funciona offline.';

  @override
  String get scanSyncIdle => 'Sem sessões pendentes de envio.';

  @override
  String get scanSyncCollecting =>
      'Varredura em andamento. O envio aguarda o encerramento.';

  @override
  String get scanSyncQueued => 'Sessões aguardando envio.';

  @override
  String get scanSyncSending => 'Enviando sessões encerradas.';

  @override
  String get scanSyncRetryable =>
      'Não foi possível concluir. Os pendentes permanecem neste aparelho.';

  @override
  String get scanSyncAuthentication =>
      'Entre novamente na mesma conta para enviar os pendentes.';

  @override
  String get scanSyncUnavailable =>
      'O serviço de coleta está indisponível. Os pendentes foram preservados.';

  @override
  String get scanSyncBlocked =>
      'O serviço não confirmou os dados. Os pendentes foram preservados; revise o serviço antes de tentar novamente.';

  @override
  String get scanSyncStorage =>
      'Não foi possível salvar todos os metadados. A coleta está pausada; tente novamente antes de fechar o app.';

  @override
  String get scanSyncFull =>
      'Limite local de 20 sessões atingido. A coleta está pausada; encerre a varredura e envie os pendentes.';

  @override
  String get scanSyncDeleted =>
      'Histórico remoto excluído e envio desativado neste aparelho.';

  @override
  String scanSyncPending(int count) {
    return 'Sessões pendentes: $count.';
  }

  @override
  String get scanSyncRetry => 'Tentar enviar pendentes';

  @override
  String get scanSyncDelete => 'Excluir histórico de metadados';

  @override
  String get scanSyncDeleteMessage =>
      'Desativa o envio e apaga os pendentes deste aparelho. Depois solicita a exclusão de todo o histórico remoto desta conta. A exclusão só será confirmada quando o servidor responder; se falhar, você poderá tentar de novo.';

  @override
  String get scanSyncDeleteConfirm => 'Desativar e excluir';

  @override
  String get scanSyncDeleteFailed =>
      'Envio desativado neste aparelho. A exclusão remota não foi confirmada. Use Excluir histórico para tentar novamente.';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get appName => 'Eyes';

  @override
  String get accountTitle => 'Conta opcional';

  @override
  String get openAccountSettings => 'Conta opcional';

  @override
  String get onboardingOptionalAccount => 'Configurar conta opcional';

  @override
  String get accountLoading => 'Carregando conta';

  @override
  String get accountLoadError =>
      'Não foi possível carregar a conta. A varredura offline continua disponível.';

  @override
  String get accountOptionalHeading => 'Conta opcional';

  @override
  String get accountConnectedHeading => 'Conta conectada';

  @override
  String get accountOfflineGuarantee =>
      'A câmera e os avisos continuam funcionando localmente, sem conta e sem internet.';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get emailHint => 'nome@exemplo.com';

  @override
  String get emailRequired => 'Informe o e-mail.';

  @override
  String get emailInvalid => 'Informe um e-mail válido.';

  @override
  String get passwordLabel => 'Senha';

  @override
  String get passwordRequired => 'Informe a senha.';

  @override
  String get showPassword => 'Mostrar senha';

  @override
  String get hidePassword => 'Ocultar senha';

  @override
  String get accountSignIn => 'Entrar';

  @override
  String get accountSigningIn => 'Entrando';

  @override
  String get accountContinueOffline => 'Continuar para a varredura offline';

  @override
  String get accountReviewAndRetry => 'Revisar dados e tentar novamente';

  @override
  String get accountSignedIn =>
      'Conta conectada. A varredura offline permanece disponível.';

  @override
  String get accountSignedOut =>
      'Sessão remota encerrada. Seus recursos locais continuam disponíveis.';

  @override
  String get accountSignOut => 'Sair da conta';

  @override
  String get syncConsentLabel => 'Permitir sincronização de metadados';

  @override
  String get syncConsentDescription =>
      'Autorize o envio das próximas sessões após encerrar a varredura. A câmera e a voz continuam funcionando offline.';

  @override
  String get syncMetadataOnlyNotice =>
      'Envia classe do objeto, confiança, proximidade relativa, direção e contadores. Sem imagens, vídeos, áudio ou localização. No servidor, os dados ficam vinculados à sua conta por até 30 dias. Pendentes locais ficam até enviar ou desativar.';

  @override
  String get syncConsentDialogTitle => 'Permitir sincronização?';

  @override
  String get syncConsentDialogMessage =>
      'Você autoriza coletar os metadados das próximas sessões neste aparelho e enviá-los após encerrar a varredura. No servidor, os dados ficam vinculados à sua conta por até 30 dias. Pendentes locais permanecem até enviar ou desativar. Nenhuma imagem, vídeo, áudio ou localização é enviado. Desativar limpa os pendentes deste aparelho; para remover o histórico remoto, use Excluir histórico. Ao autorizar outra conta, os pendentes da conta anterior neste aparelho serão apagados.';

  @override
  String get syncConsentConfirm => 'Permitir';

  @override
  String get syncConsentEnabled => 'Consentimento de sincronização ativado.';

  @override
  String get syncConsentRevoked =>
      'Consentimento revogado e fila local de sincronização apagada.';

  @override
  String get onboardingTitle => 'Primeiros passos';

  @override
  String onboardingProgress(int current, int total) {
    return 'Etapa $current de $total';
  }

  @override
  String get onboardingWelcomeTitle => 'Bem-vindo ao Eyes';

  @override
  String get onboardingWelcomeBody =>
      'O Eyes usa a câmera do celular para reconhecer alguns objetos e oferecer avisos curtos por voz e vibração.';

  @override
  String get onboardingSafetyTitle => 'Use como apoio complementar';

  @override
  String get onboardingSafetyBody =>
      'O Eyes pode errar ou não perceber um obstáculo. Ele não substitui bengala, cão-guia, orientação humana nem técnicas de mobilidade.';

  @override
  String get onboardingPrivacyTitle => 'Suas imagens permanecem no aparelho';

  @override
  String get onboardingPrivacyBody =>
      'A câmera é processada localmente durante a varredura. O Eyes não salva fotos ou vídeos e a função assistiva opera sem internet e sem conta. Nenhum metadado é enviado.';

  @override
  String get onboardingFeedbackTitle => 'Prepare voz e vibração';

  @override
  String get onboardingFeedbackBody =>
      'Teste os dois canais antes de usar. A vibração complementa a voz e nunca é o único aviso.';

  @override
  String get onboardingCameraTitle => 'Permita a câmera quando estiver pronto';

  @override
  String get onboardingCameraBody =>
      'A câmera é necessária somente para a varredura. A solicitação acontece agora, depois desta explicação.';

  @override
  String get onboardingAllowCamera => 'Permitir acesso à câmera';

  @override
  String get onboardingTryCameraAgain => 'Solicitar câmera novamente';

  @override
  String get onboardingCameraGranted =>
      'Câmera autorizada. O modo assistivo está pronto para iniciar.';

  @override
  String get onboardingCameraDenied =>
      'A câmera não foi autorizada. Você pode tentar novamente ou continuar e permitir depois.';

  @override
  String get onboardingCameraPermanentlyDenied =>
      'A permissão está bloqueada. Abra as configurações do aparelho para autorizar a câmera.';

  @override
  String get onboardingCameraRestricted =>
      'Este aparelho ou perfil restringe a câmera. Verifique as configurações ou continue sem a varredura.';

  @override
  String get onboardingContinueOffline => 'Continuar sem conta no modo offline';

  @override
  String get onboardingContinueWithoutCamera =>
      'Continuar sem câmera por enquanto';

  @override
  String get onboardingLoadError =>
      'Não foi possível carregar ou salvar os primeiros passos. Tente novamente.';

  @override
  String get repeatOnboarding => 'Repetir primeiros passos';

  @override
  String get repeatFeedbackTests => 'Repetir testes de voz e vibração';

  @override
  String get next => 'Avançar';

  @override
  String get back => 'Voltar';

  @override
  String get close => 'Fechar';

  @override
  String get homeTitle => 'Reconhecer objetos';

  @override
  String get foundationReady =>
      'Abra a câmera para ouvir o que está à sua frente.';

  @override
  String get homeOfflineTitle => 'Funciona sem internet.';

  @override
  String get homeOfflineMessage =>
      'A câmera e a inteligência artificial processam as imagens neste aparelho. Nenhuma foto ou vídeo é salvo.';

  @override
  String get homeSupportTitle => 'Ajustes e suporte';

  @override
  String get homeSupportDescription =>
      'Personalize os avisos, consulte orientações de segurança ou conecte uma conta opcional.';

  @override
  String get accessibilityDescription =>
      'Este aplicativo respeita o tamanho de fonte do sistema, oferece alto contraste e foi estruturado para funcionar com o TalkBack.';

  @override
  String get testFeedbackLabel => 'Testar som e vibração';

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
  String get cameraPageTitle => 'Câmera';

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
  String get visionFailed => 'Não foi possível iniciar.';

  @override
  String get visionFailedHelp =>
      'A varredura não foi iniciada. Tente novamente.';

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
  String get objectPerson => 'Pessoa';

  @override
  String get objectChair => 'Cadeira';

  @override
  String get objectTable => 'Mesa';

  @override
  String get objectBackpack => 'Mochila';

  @override
  String proximityDistant(String object) {
    return '$object distante.';
  }

  @override
  String proximityAttention(String object) {
    return '$object próxima. Atenção.';
  }

  @override
  String proximityVeryNear(String object) {
    return '$object muito próxima. Cuidado.';
  }

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
  String get recoveryCameraPermissionTitle => 'A câmera precisa de permissão';

  @override
  String get recoveryCameraPermissionBlockedTitle =>
      'Permissão de câmera bloqueada';

  @override
  String get recoveryCameraRestrictedTitle => 'A câmera está restrita';

  @override
  String get recoveryCameraTimeoutTitle => 'A câmera demorou para iniciar';

  @override
  String get recoveryCameraInterruptedTitle => 'A câmera foi interrompida';

  @override
  String get recoveryModelTimeoutTitle =>
      'A inteligência artificial demorou para iniciar';

  @override
  String get recoveryModelTimeoutMessage =>
      'A varredura permaneceu desligada. Tente preparar a inteligência artificial novamente.';

  @override
  String get recoveryModelUnavailableTitle => 'Não foi possível iniciar.';

  @override
  String get recoveryModelInvalidMessage =>
      'O recurso de reconhecimento não pôde ser validado. Tente novamente ou volte ao início com segurança.';

  @override
  String get recoveryModelMemoryMessage =>
      'Faltou memória para iniciar. Feche outros aplicativos e tente novamente.';

  @override
  String get recoveryModelDelegateMessage =>
      'O acelerador do aparelho não está disponível. Tente novamente usando o processamento compatível.';

  @override
  String get recoverySpeechTitle => 'Avisos por voz indisponíveis';

  @override
  String get recoverySpeechMessage =>
      'A varredura pode continuar, mas os avisos falados podem não funcionar. Verifique as configurações de voz antes de usar.';

  @override
  String get recoveryHapticsTitle => 'Vibração indisponível';

  @override
  String get recoveryHapticsMessage =>
      'A varredura pode continuar com avisos por voz e texto. Verifique as configurações de vibração.';

  @override
  String get recoveryPreferencesTitle => 'Preferências não foram salvas';

  @override
  String get recoveryPreferencesMessage =>
      'Os padrões seguros estão ativos nesta sessão. Revise as configurações quando puder.';

  @override
  String get recoveryLoginTitle => 'Não foi possível entrar';

  @override
  String get recoveryInvalidCredentialsMessage =>
      'Confira os dados informados ou continue usando a varredura offline.';

  @override
  String get recoverySessionTitle => 'Sua sessão terminou';

  @override
  String get recoverySessionMessage =>
      'Entre novamente quando houver conexão. A varredura offline continua disponível.';

  @override
  String get recoveryNetworkTitle => 'Sem conexão com o serviço';

  @override
  String get recoveryNetworkMessage =>
      'A sincronização ficará pendente. A varredura local continua disponível.';

  @override
  String get recoverySyncTitle => 'Sincronização pendente';

  @override
  String get recoverySyncMessage =>
      'Os dados permitidos serão enviados quando a conexão voltar. A varredura local não foi interrompida.';

  @override
  String get recoveryBatteryTitle => 'Bateria baixa';

  @override
  String get recoveryBatteryMessage =>
      'O ritmo da varredura foi reduzido para preservar a bateria.';

  @override
  String get recoveryThermalTitle => 'Aparelho aquecido';

  @override
  String get recoveryThermalMessage =>
      'O ritmo da varredura foi reduzido até o aparelho esfriar.';

  @override
  String get recoveryUnexpectedTitle => 'Não foi possível iniciar a varredura';

  @override
  String get recoveryUnexpectedMessage =>
      'A varredura permaneceu desligada. Tente novamente ou volte ao início com segurança.';

  @override
  String get recoveryContinueOffline => 'Continuar no modo offline';

  @override
  String get recoveryReturnHome => 'Voltar ao início';

  @override
  String get assistiveScanTitle => 'Varredura assistiva';

  @override
  String get openHelpAndSafety => 'Ajuda e segurança';

  @override
  String get scanCapabilitiesTitle => 'Recursos ativos';

  @override
  String get scanAudioAvailable => 'Avisos por voz disponíveis';

  @override
  String get scanAudioUnavailable => 'Avisos por voz indisponíveis';

  @override
  String get scanHapticsAvailable => 'Vibração ativa';

  @override
  String get scanHapticsDisabled => 'Vibração desativada nas configurações';

  @override
  String get scanHapticsUnavailable => 'Vibração indisponível';

  @override
  String get scanOfflineAvailable => 'Varredura offline disponível';

  @override
  String get scanStart => 'Iniciar varredura';

  @override
  String get scanStartHint => 'Ativa a câmera e os avisos de obstáculos';

  @override
  String get scanPause => 'Pausar varredura';

  @override
  String get scanPauseHint =>
      'Interrompe a câmera e libera os recursos do aparelho';

  @override
  String get scanResume => 'Retomar varredura';

  @override
  String get scanResumeHint => 'Reativa a câmera e os avisos de obstáculos';

  @override
  String get scanPreparingHint => 'Aguarde enquanto os recursos são preparados';

  @override
  String get scanEnded =>
      'Varredura encerrada. A câmera e a inteligência artificial estão desligadas.';

  @override
  String get scanStop => 'Encerrar varredura';

  @override
  String get scanStopHint =>
      'Solicita confirmação antes de desligar a varredura';

  @override
  String get scanStopDialogTitle => 'Encerrar a varredura?';

  @override
  String get scanStopDialogMessage =>
      'Você deixará de receber avisos de obstáculos até iniciar uma nova varredura.';

  @override
  String get scanKeepRunning => 'Continuar varredura';

  @override
  String get scanConfirmStop => 'Encerrar agora';

  @override
  String get helpAndSafetyTitle => 'Ajuda e segurança';

  @override
  String get helpAndSafetyIntro =>
      'Orientações para usar a câmera e os avisos com segurança.';

  @override
  String get helpSafetyHeading => 'Uso seguro';

  @override
  String get helpSafetyBody =>
      'O Eyes é um apoio complementar. Ele não substitui bengala, cão-guia, orientação humana nem técnicas de mobilidade.';

  @override
  String get helpPrivacyHeading => 'Privacidade';

  @override
  String get helpPrivacyBody =>
      'As imagens são processadas localmente durante a varredura e não são salvas como foto ou vídeo.';

  @override
  String get helpScanningHeading => 'Como usar a varredura';

  @override
  String get helpScanningBody =>
      'Mantenha a câmera traseira livre. Inicie a varredura e siga os avisos curtos de voz e vibração. Pause ou encerre quando não precisar dos alertas.';

  @override
  String get helpPermissionHeading => 'Permissão da câmera';

  @override
  String get helpPermissionBody =>
      'A câmera é solicitada somente ao iniciar. Se a permissão estiver bloqueada, use a ação para abrir as configurações do aparelho.';

  @override
  String get openFeedbackSettings => 'Áudio e alertas';

  @override
  String get feedbackSettingsTitle => 'Áudio e alertas';

  @override
  String get feedbackSettingsIntro =>
      'Seus ajustes ficam salvos apenas neste aparelho.';

  @override
  String get appearanceSectionTitle => 'Aparência e contraste';

  @override
  String get appearanceSectionDescription =>
      'Escolha uma opção confortável para leitura. O alto contraste reforça bordas e diferenças entre as cores.';

  @override
  String get appearanceLabel => 'Tema do aplicativo';

  @override
  String get appearanceSystem => 'Seguir configuração do aparelho';

  @override
  String get appearanceSystemShort => 'Padrão do aparelho';

  @override
  String get appearanceLight => 'Claro';

  @override
  String get appearanceDark => 'Escuro';

  @override
  String get appearanceHighContrastLight => 'Alto contraste claro';

  @override
  String get appearanceHighContrastDark => 'Alto contraste escuro';

  @override
  String get appearanceSaved => 'Aparência atualizada.';

  @override
  String get appearanceSaveFailed =>
      'Não foi possível salvar a aparência. A configuração anterior foi mantida.';

  @override
  String get loadingFeedbackSettings =>
      'Carregando configurações de áudio e alertas';

  @override
  String get feedbackSettingsLoadError =>
      'Não foi possível carregar as configurações. Tente novamente.';

  @override
  String get voiceSectionTitle => 'Voz';

  @override
  String get speechRateLabel => 'Velocidade da voz';

  @override
  String speechRateValue(int percent) {
    return '$percent por cento';
  }

  @override
  String get speechRateRange =>
      'Ajustável de 30 a 70 por cento. Deslize para cima ou para baixo para alterar.';

  @override
  String get speechVolumeLabel => 'Volume da voz';

  @override
  String percentValue(int percent) {
    return '$percent por cento';
  }

  @override
  String get speechVolumeRange =>
      'Ajustável de zero a 100 por cento. Deslize para cima ou para baixo para alterar.';

  @override
  String get voiceDetailLabel => 'Nível de detalhe';

  @override
  String get voiceDetailConcise => 'Frases curtas';

  @override
  String get voiceDetailDetailed => 'Frases com orientação';

  @override
  String get testVoice => 'Testar voz';

  @override
  String get voiceTestPhrase => 'Teste de voz do Eyes concluído.';

  @override
  String get alertsSectionTitle => 'Alertas';

  @override
  String get announceAttentionLabel => 'Avisar também objetos próximos';

  @override
  String get announceAttentionDescription =>
      'Quando desativado, o Eyes fala apenas sobre objetos muito próximos.';

  @override
  String get sensitivityLabel => 'Frequência dos alertas';

  @override
  String get sensitivityConservative => 'Conservador';

  @override
  String get sensitivityBalanced => 'Equilibrado';

  @override
  String get sensitivityFewerAlerts => 'Menos alertas';

  @override
  String get sensitivityConservativeDescription =>
      'Avisa mais cedo e repete com maior frequência.';

  @override
  String get sensitivityBalancedDescription =>
      'Equilibra segurança e quantidade de avisos.';

  @override
  String get sensitivityFewerAlertsDescription =>
      'Exige mais persistência e aumenta o intervalo entre avisos.';

  @override
  String get hapticsSectionTitle => 'Vibração';

  @override
  String get hapticsEnabledLabel => 'Usar vibração';

  @override
  String get hapticsDescription =>
      'Alertas muito próximos usam duas vibrações curtas como reforço ao áudio.';

  @override
  String get testHaptics => 'Testar vibração';

  @override
  String get privacySectionTitle => 'Privacidade e sincronização';

  @override
  String get feedbackPrivacyDescription =>
      'O reconhecimento e os alertas funcionam localmente, sem enviar imagens. As preferências não contêm dados sensíveis e não são sincronizadas no MVP.';

  @override
  String get restoreDefaults => 'Restaurar configurações padrão';

  @override
  String get restoreDefaultsTitle => 'Restaurar configurações?';

  @override
  String get restoreDefaultsDescription =>
      'Velocidade, volume, alertas e vibração voltarão aos valores recomendados.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirmRestore => 'Restaurar';

  @override
  String get preferencesSaved => 'Configuração salva.';

  @override
  String get defaultsRestored => 'Configurações padrão restauradas.';

  @override
  String get voiceTestSucceeded => 'Teste de voz concluído.';

  @override
  String get hapticTestSucceeded => 'Teste de vibração concluído.';

  @override
  String get speechUnavailable =>
      'A voz está indisponível. Verifique o mecanismo de síntese do aparelho e tente novamente.';

  @override
  String get hapticsUnavailable =>
      'A vibração não está disponível neste aparelho. Os avisos por voz continuam funcionando.';

  @override
  String get preferencesSaveFailed =>
      'Não foi possível salvar a configuração. Tente novamente.';

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

  @override
  String get homeSettingsAction => 'Abrir configurações';

  @override
  String get homePrivacyNote => 'Nenhuma foto ou vídeo é salvo.';

  @override
  String get scanSyncTitle => 'Envio de metadados';

  @override
  String get scanSyncDisabled =>
      'Envio desativado. A assistência funciona offline.';

  @override
  String get scanSyncIdle => 'Sem sessões pendentes de envio.';

  @override
  String get scanSyncCollecting =>
      'Varredura em andamento. O envio aguarda o encerramento.';

  @override
  String get scanSyncQueued => 'Sessões aguardando envio.';

  @override
  String get scanSyncSending => 'Enviando sessões encerradas.';

  @override
  String get scanSyncRetryable =>
      'Não foi possível concluir. Os pendentes permanecem neste aparelho.';

  @override
  String get scanSyncAuthentication =>
      'Entre novamente na mesma conta para enviar os pendentes.';

  @override
  String get scanSyncUnavailable =>
      'O serviço de coleta está indisponível. Os pendentes foram preservados.';

  @override
  String get scanSyncBlocked =>
      'O serviço não confirmou os dados. Os pendentes foram preservados; revise o serviço antes de tentar novamente.';

  @override
  String get scanSyncStorage =>
      'Não foi possível salvar todos os metadados. A coleta está pausada; tente novamente antes de fechar o app.';

  @override
  String get scanSyncFull =>
      'Limite local de 20 sessões atingido. A coleta está pausada; encerre a varredura e envie os pendentes.';

  @override
  String get scanSyncDeleted =>
      'Histórico remoto excluído e envio desativado neste aparelho.';

  @override
  String scanSyncPending(int count) {
    return 'Sessões pendentes: $count.';
  }

  @override
  String get scanSyncRetry => 'Tentar enviar pendentes';

  @override
  String get scanSyncDelete => 'Excluir histórico de metadados';

  @override
  String get scanSyncDeleteMessage =>
      'Desativa o envio e apaga os pendentes deste aparelho. Depois solicita a exclusão de todo o histórico remoto desta conta. A exclusão só será confirmada quando o servidor responder; se falhar, você poderá tentar de novo.';

  @override
  String get scanSyncDeleteConfirm => 'Desativar e excluir';

  @override
  String get scanSyncDeleteFailed =>
      'Envio desativado neste aparelho. A exclusão remota não foi confirmada. Use Excluir histórico para tentar novamente.';
}
