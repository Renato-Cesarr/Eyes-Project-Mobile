import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('pt'),
    Locale('pt', 'BR'),
  ];

  /// No description provided for @appName.
  ///
  /// In pt, this message translates to:
  /// **'Eyes'**
  String get appName;

  /// No description provided for @homeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Assistência visual ao seu alcance'**
  String get homeTitle;

  /// No description provided for @foundationReady.
  ///
  /// In pt, this message translates to:
  /// **'A fundação do aplicativo está pronta para receber as funcionalidades do MVP.'**
  String get foundationReady;

  /// No description provided for @accessibilityDescription.
  ///
  /// In pt, this message translates to:
  /// **'Este aplicativo respeita o tamanho de fonte do sistema, oferece alto contraste e foi estruturado para funcionar com o TalkBack.'**
  String get accessibilityDescription;

  /// No description provided for @testFeedbackLabel.
  ///
  /// In pt, this message translates to:
  /// **'Testar vibração e som'**
  String get testFeedbackLabel;

  /// No description provided for @testFeedbackHint.
  ///
  /// In pt, this message translates to:
  /// **'Ativa uma confirmação tátil e sonora do aparelho'**
  String get testFeedbackHint;

  /// No description provided for @feedbackConfirmed.
  ///
  /// In pt, this message translates to:
  /// **'Feedback tátil e sonoro confirmado.'**
  String get feedbackConfirmed;

  /// No description provided for @feedbackUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível reproduzir o feedback neste aparelho.'**
  String get feedbackUnavailable;

  /// No description provided for @loading.
  ///
  /// In pt, this message translates to:
  /// **'Carregando'**
  String get loading;

  /// No description provided for @unexpectedError.
  ///
  /// In pt, this message translates to:
  /// **'Ocorreu um erro inesperado.'**
  String get unexpectedError;

  /// No description provided for @tryAgain.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get tryAgain;

  /// No description provided for @notFoundTitle.
  ///
  /// In pt, this message translates to:
  /// **'Tela não encontrada'**
  String get notFoundTitle;

  /// No description provided for @notFoundMessage.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível encontrar a tela solicitada.'**
  String get notFoundMessage;

  /// No description provided for @goHome.
  ///
  /// In pt, this message translates to:
  /// **'Voltar ao início'**
  String get goHome;

  /// No description provided for @openCamera.
  ///
  /// In pt, this message translates to:
  /// **'Abrir câmera'**
  String get openCamera;

  /// No description provided for @cameraPageTitle.
  ///
  /// In pt, this message translates to:
  /// **'Câmera e varredura'**
  String get cameraPageTitle;

  /// No description provided for @cameraPrivacyNotice.
  ///
  /// In pt, this message translates to:
  /// **'A imagem é processada apenas enquanto esta tela está ativa. O aplicativo não salva fotos nem vídeos.'**
  String get cameraPrivacyNotice;

  /// No description provided for @scanStatusLabel.
  ///
  /// In pt, this message translates to:
  /// **'Estado da varredura'**
  String get scanStatusLabel;

  /// No description provided for @visionPreparing.
  ///
  /// In pt, this message translates to:
  /// **'Preparando inteligência artificial.'**
  String get visionPreparing;

  /// No description provided for @visionRecovering.
  ///
  /// In pt, this message translates to:
  /// **'Recuperando a inteligência artificial.'**
  String get visionRecovering;

  /// No description provided for @visionReady.
  ///
  /// In pt, this message translates to:
  /// **'Inteligência artificial pronta. Inicie a câmera quando desejar.'**
  String get visionReady;

  /// No description provided for @visionPaused.
  ///
  /// In pt, this message translates to:
  /// **'Varredura pausada e recursos liberados.'**
  String get visionPaused;

  /// No description provided for @visionFailed.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao iniciar inteligência artificial.'**
  String get visionFailed;

  /// No description provided for @visionFailedHelp.
  ///
  /// In pt, this message translates to:
  /// **'A varredura não foi iniciada. Tente preparar a inteligência artificial novamente.'**
  String get visionFailedHelp;

  /// No description provided for @visionRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar iniciar inteligência artificial novamente'**
  String get visionRetry;

  /// No description provided for @scanReady.
  ///
  /// In pt, this message translates to:
  /// **'Câmera pronta. Varredura assistiva ativa.'**
  String get scanReady;

  /// No description provided for @detectedPerson.
  ///
  /// In pt, this message translates to:
  /// **'Pessoa detectada.'**
  String get detectedPerson;

  /// No description provided for @detectedChair.
  ///
  /// In pt, this message translates to:
  /// **'Cadeira detectada.'**
  String get detectedChair;

  /// No description provided for @detectedTable.
  ///
  /// In pt, this message translates to:
  /// **'Mesa detectada.'**
  String get detectedTable;

  /// No description provided for @detectedBackpack.
  ///
  /// In pt, this message translates to:
  /// **'Mochila detectada.'**
  String get detectedBackpack;

  /// No description provided for @objectPerson.
  ///
  /// In pt, this message translates to:
  /// **'Pessoa'**
  String get objectPerson;

  /// No description provided for @objectChair.
  ///
  /// In pt, this message translates to:
  /// **'Cadeira'**
  String get objectChair;

  /// No description provided for @objectTable.
  ///
  /// In pt, this message translates to:
  /// **'Mesa'**
  String get objectTable;

  /// No description provided for @objectBackpack.
  ///
  /// In pt, this message translates to:
  /// **'Mochila'**
  String get objectBackpack;

  /// No description provided for @proximityDistant.
  ///
  /// In pt, this message translates to:
  /// **'{object} distante.'**
  String proximityDistant(String object);

  /// No description provided for @proximityAttention.
  ///
  /// In pt, this message translates to:
  /// **'{object} próxima. Atenção.'**
  String proximityAttention(String object);

  /// No description provided for @proximityVeryNear.
  ///
  /// In pt, this message translates to:
  /// **'{object} muito próxima. Cuidado.'**
  String proximityVeryNear(String object);

  /// No description provided for @cameraStatusLabel.
  ///
  /// In pt, this message translates to:
  /// **'Estado da câmera'**
  String get cameraStatusLabel;

  /// No description provided for @cameraStart.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar câmera'**
  String get cameraStart;

  /// No description provided for @cameraPause.
  ///
  /// In pt, this message translates to:
  /// **'Pausar câmera'**
  String get cameraPause;

  /// No description provided for @cameraResume.
  ///
  /// In pt, this message translates to:
  /// **'Retomar câmera'**
  String get cameraResume;

  /// No description provided for @cameraStop.
  ///
  /// In pt, this message translates to:
  /// **'Encerrar câmera'**
  String get cameraStop;

  /// No description provided for @cameraPreparing.
  ///
  /// In pt, this message translates to:
  /// **'Preparando câmera'**
  String get cameraPreparing;

  /// No description provided for @visionPreparingAction.
  ///
  /// In pt, this message translates to:
  /// **'Preparando inteligência artificial'**
  String get visionPreparingAction;

  /// No description provided for @cameraOpenSettings.
  ///
  /// In pt, this message translates to:
  /// **'Abrir configurações do aparelho'**
  String get cameraOpenSettings;

  /// No description provided for @cameraUnexpectedError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar o controle da câmera.'**
  String get cameraUnexpectedError;

  /// No description provided for @cameraStatusIdle.
  ///
  /// In pt, this message translates to:
  /// **'Pronta para iniciar.'**
  String get cameraStatusIdle;

  /// No description provided for @cameraStatusRequestingPermission.
  ///
  /// In pt, this message translates to:
  /// **'Aguardando permissão para usar a câmera.'**
  String get cameraStatusRequestingPermission;

  /// No description provided for @cameraStatusPreparing.
  ///
  /// In pt, this message translates to:
  /// **'Preparando a câmera.'**
  String get cameraStatusPreparing;

  /// No description provided for @cameraStatusStreaming.
  ///
  /// In pt, this message translates to:
  /// **'Câmera ativa e recebendo imagens.'**
  String get cameraStatusStreaming;

  /// No description provided for @cameraStatusPaused.
  ///
  /// In pt, this message translates to:
  /// **'Câmera pausada e recursos liberados.'**
  String get cameraStatusPaused;

  /// No description provided for @cameraStatusDenied.
  ///
  /// In pt, this message translates to:
  /// **'Permissão de câmera negada.'**
  String get cameraStatusDenied;

  /// No description provided for @cameraStatusPermanentlyDenied.
  ///
  /// In pt, this message translates to:
  /// **'Permissão de câmera bloqueada nas configurações.'**
  String get cameraStatusPermanentlyDenied;

  /// No description provided for @cameraStatusBusy.
  ///
  /// In pt, this message translates to:
  /// **'A câmera está sendo usada por outro aplicativo.'**
  String get cameraStatusBusy;

  /// No description provided for @cameraStatusUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Câmera indisponível.'**
  String get cameraStatusUnavailable;

  /// No description provided for @cameraPermissionDeniedHelp.
  ///
  /// In pt, this message translates to:
  /// **'Autorize a câmera para iniciar a varredura. Você pode tentar novamente.'**
  String get cameraPermissionDeniedHelp;

  /// No description provided for @cameraPermissionPermanentlyDeniedHelp.
  ///
  /// In pt, this message translates to:
  /// **'Abra as configurações do aparelho e permita o acesso à câmera para o Eyes.'**
  String get cameraPermissionPermanentlyDeniedHelp;

  /// No description provided for @cameraPermissionRestrictedHelp.
  ///
  /// In pt, this message translates to:
  /// **'Este aparelho ou perfil restringe o acesso à câmera.'**
  String get cameraPermissionRestrictedHelp;

  /// No description provided for @cameraBusyHelp.
  ///
  /// In pt, this message translates to:
  /// **'Feche outros aplicativos que estejam usando a câmera e tente novamente.'**
  String get cameraBusyHelp;

  /// No description provided for @cameraMissingHelp.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma câmera compatível foi encontrada neste aparelho.'**
  String get cameraMissingHelp;

  /// No description provided for @cameraTimeoutHelp.
  ///
  /// In pt, this message translates to:
  /// **'A câmera demorou mais que o esperado para iniciar. Tente novamente.'**
  String get cameraTimeoutHelp;

  /// No description provided for @cameraInitializationHelp.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível preparar a câmera. Verifique o aparelho e tente novamente.'**
  String get cameraInitializationHelp;

  /// No description provided for @cameraStreamHelp.
  ///
  /// In pt, this message translates to:
  /// **'A câmera parou de fornecer imagens. Tente iniciar novamente.'**
  String get cameraStreamHelp;

  /// No description provided for @recoveryCameraPermissionTitle.
  ///
  /// In pt, this message translates to:
  /// **'A câmera precisa de permissão'**
  String get recoveryCameraPermissionTitle;

  /// No description provided for @recoveryCameraPermissionBlockedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Permissão de câmera bloqueada'**
  String get recoveryCameraPermissionBlockedTitle;

  /// No description provided for @recoveryCameraRestrictedTitle.
  ///
  /// In pt, this message translates to:
  /// **'A câmera está restrita'**
  String get recoveryCameraRestrictedTitle;

  /// No description provided for @recoveryCameraTimeoutTitle.
  ///
  /// In pt, this message translates to:
  /// **'A câmera demorou para iniciar'**
  String get recoveryCameraTimeoutTitle;

  /// No description provided for @recoveryCameraInterruptedTitle.
  ///
  /// In pt, this message translates to:
  /// **'A câmera foi interrompida'**
  String get recoveryCameraInterruptedTitle;

  /// No description provided for @recoveryModelTimeoutTitle.
  ///
  /// In pt, this message translates to:
  /// **'A inteligência artificial demorou para iniciar'**
  String get recoveryModelTimeoutTitle;

  /// No description provided for @recoveryModelTimeoutMessage.
  ///
  /// In pt, this message translates to:
  /// **'A varredura permaneceu desligada. Tente preparar a inteligência artificial novamente.'**
  String get recoveryModelTimeoutMessage;

  /// No description provided for @recoveryModelUnavailableTitle.
  ///
  /// In pt, this message translates to:
  /// **'Inteligência artificial indisponível'**
  String get recoveryModelUnavailableTitle;

  /// No description provided for @recoveryModelInvalidMessage.
  ///
  /// In pt, this message translates to:
  /// **'O recurso de reconhecimento não pôde ser validado. Tente novamente ou volte ao início com segurança.'**
  String get recoveryModelInvalidMessage;

  /// No description provided for @recoveryModelMemoryMessage.
  ///
  /// In pt, this message translates to:
  /// **'O aparelho não conseguiu reservar memória para o reconhecimento. Feche outros aplicativos e tente novamente.'**
  String get recoveryModelMemoryMessage;

  /// No description provided for @recoveryModelDelegateMessage.
  ///
  /// In pt, this message translates to:
  /// **'O acelerador do aparelho não está disponível. Tente novamente usando o processamento compatível.'**
  String get recoveryModelDelegateMessage;

  /// No description provided for @recoverySpeechTitle.
  ///
  /// In pt, this message translates to:
  /// **'Avisos por voz indisponíveis'**
  String get recoverySpeechTitle;

  /// No description provided for @recoverySpeechMessage.
  ///
  /// In pt, this message translates to:
  /// **'A varredura pode continuar, mas os avisos falados podem não funcionar. Verifique as configurações de voz antes de usar.'**
  String get recoverySpeechMessage;

  /// No description provided for @recoveryHapticsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Vibração indisponível'**
  String get recoveryHapticsTitle;

  /// No description provided for @recoveryHapticsMessage.
  ///
  /// In pt, this message translates to:
  /// **'A varredura pode continuar com avisos por voz e texto. Verifique as configurações de vibração.'**
  String get recoveryHapticsMessage;

  /// No description provided for @recoveryPreferencesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Preferências não foram salvas'**
  String get recoveryPreferencesTitle;

  /// No description provided for @recoveryPreferencesMessage.
  ///
  /// In pt, this message translates to:
  /// **'Os padrões seguros estão ativos nesta sessão. Revise as configurações quando puder.'**
  String get recoveryPreferencesMessage;

  /// No description provided for @recoveryLoginTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível entrar'**
  String get recoveryLoginTitle;

  /// No description provided for @recoveryInvalidCredentialsMessage.
  ///
  /// In pt, this message translates to:
  /// **'Confira os dados informados ou continue usando a varredura offline.'**
  String get recoveryInvalidCredentialsMessage;

  /// No description provided for @recoverySessionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sua sessão terminou'**
  String get recoverySessionTitle;

  /// No description provided for @recoverySessionMessage.
  ///
  /// In pt, this message translates to:
  /// **'Entre novamente quando houver conexão. A varredura offline continua disponível.'**
  String get recoverySessionMessage;

  /// No description provided for @recoveryNetworkTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão com o serviço'**
  String get recoveryNetworkTitle;

  /// No description provided for @recoveryNetworkMessage.
  ///
  /// In pt, this message translates to:
  /// **'A sincronização ficará pendente. A varredura local continua disponível.'**
  String get recoveryNetworkMessage;

  /// No description provided for @recoverySyncTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sincronização pendente'**
  String get recoverySyncTitle;

  /// No description provided for @recoverySyncMessage.
  ///
  /// In pt, this message translates to:
  /// **'Os dados permitidos serão enviados quando a conexão voltar. A varredura local não foi interrompida.'**
  String get recoverySyncMessage;

  /// No description provided for @recoveryBatteryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Bateria baixa'**
  String get recoveryBatteryTitle;

  /// No description provided for @recoveryBatteryMessage.
  ///
  /// In pt, this message translates to:
  /// **'O ritmo da varredura foi reduzido para preservar a bateria.'**
  String get recoveryBatteryMessage;

  /// No description provided for @recoveryThermalTitle.
  ///
  /// In pt, this message translates to:
  /// **'Aparelho aquecido'**
  String get recoveryThermalTitle;

  /// No description provided for @recoveryThermalMessage.
  ///
  /// In pt, this message translates to:
  /// **'O ritmo da varredura foi reduzido até o aparelho esfriar.'**
  String get recoveryThermalMessage;

  /// No description provided for @recoveryUnexpectedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível iniciar a varredura'**
  String get recoveryUnexpectedTitle;

  /// No description provided for @recoveryUnexpectedMessage.
  ///
  /// In pt, this message translates to:
  /// **'A varredura permaneceu desligada. Tente novamente ou volte ao início com segurança.'**
  String get recoveryUnexpectedMessage;

  /// No description provided for @recoveryContinueOffline.
  ///
  /// In pt, this message translates to:
  /// **'Continuar no modo offline'**
  String get recoveryContinueOffline;

  /// No description provided for @recoveryReturnHome.
  ///
  /// In pt, this message translates to:
  /// **'Voltar ao início'**
  String get recoveryReturnHome;

  /// No description provided for @openFeedbackSettings.
  ///
  /// In pt, this message translates to:
  /// **'Configurações de áudio e alertas'**
  String get openFeedbackSettings;

  /// No description provided for @feedbackSettingsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Áudio, alertas e vibração'**
  String get feedbackSettingsTitle;

  /// No description provided for @feedbackSettingsIntro.
  ///
  /// In pt, this message translates to:
  /// **'Escolha como o Eyes deve avisar sobre os objetos ao seu redor. Estas opções ficam somente neste aparelho.'**
  String get feedbackSettingsIntro;

  /// No description provided for @loadingFeedbackSettings.
  ///
  /// In pt, this message translates to:
  /// **'Carregando configurações de áudio e alertas'**
  String get loadingFeedbackSettings;

  /// No description provided for @feedbackSettingsLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as configurações. Tente novamente.'**
  String get feedbackSettingsLoadError;

  /// No description provided for @voiceSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Voz'**
  String get voiceSectionTitle;

  /// No description provided for @speechRateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Velocidade da voz'**
  String get speechRateLabel;

  /// No description provided for @speechRateValue.
  ///
  /// In pt, this message translates to:
  /// **'{percent} por cento'**
  String speechRateValue(int percent);

  /// No description provided for @speechRateRange.
  ///
  /// In pt, this message translates to:
  /// **'Ajustável de 30 a 70 por cento. Deslize para cima ou para baixo para alterar.'**
  String get speechRateRange;

  /// No description provided for @speechVolumeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Volume da voz'**
  String get speechVolumeLabel;

  /// No description provided for @percentValue.
  ///
  /// In pt, this message translates to:
  /// **'{percent} por cento'**
  String percentValue(int percent);

  /// No description provided for @speechVolumeRange.
  ///
  /// In pt, this message translates to:
  /// **'Ajustável de zero a 100 por cento. Deslize para cima ou para baixo para alterar.'**
  String get speechVolumeRange;

  /// No description provided for @voiceDetailLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nível de detalhe'**
  String get voiceDetailLabel;

  /// No description provided for @voiceDetailConcise.
  ///
  /// In pt, this message translates to:
  /// **'Frases curtas'**
  String get voiceDetailConcise;

  /// No description provided for @voiceDetailDetailed.
  ///
  /// In pt, this message translates to:
  /// **'Frases com orientação'**
  String get voiceDetailDetailed;

  /// No description provided for @testVoice.
  ///
  /// In pt, this message translates to:
  /// **'Testar voz'**
  String get testVoice;

  /// No description provided for @voiceTestPhrase.
  ///
  /// In pt, this message translates to:
  /// **'Teste de voz do Eyes concluído.'**
  String get voiceTestPhrase;

  /// No description provided for @alertsSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Alertas'**
  String get alertsSectionTitle;

  /// No description provided for @announceAttentionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Avisar também objetos próximos'**
  String get announceAttentionLabel;

  /// No description provided for @announceAttentionDescription.
  ///
  /// In pt, this message translates to:
  /// **'Quando desativado, o Eyes fala apenas sobre objetos muito próximos.'**
  String get announceAttentionDescription;

  /// No description provided for @sensitivityLabel.
  ///
  /// In pt, this message translates to:
  /// **'Frequência dos alertas'**
  String get sensitivityLabel;

  /// No description provided for @sensitivityConservative.
  ///
  /// In pt, this message translates to:
  /// **'Conservador'**
  String get sensitivityConservative;

  /// No description provided for @sensitivityBalanced.
  ///
  /// In pt, this message translates to:
  /// **'Equilibrado'**
  String get sensitivityBalanced;

  /// No description provided for @sensitivityFewerAlerts.
  ///
  /// In pt, this message translates to:
  /// **'Menos alertas'**
  String get sensitivityFewerAlerts;

  /// No description provided for @sensitivityConservativeDescription.
  ///
  /// In pt, this message translates to:
  /// **'Avisa mais cedo e repete com maior frequência.'**
  String get sensitivityConservativeDescription;

  /// No description provided for @sensitivityBalancedDescription.
  ///
  /// In pt, this message translates to:
  /// **'Equilibra segurança e quantidade de avisos.'**
  String get sensitivityBalancedDescription;

  /// No description provided for @sensitivityFewerAlertsDescription.
  ///
  /// In pt, this message translates to:
  /// **'Exige mais persistência e aumenta o intervalo entre avisos.'**
  String get sensitivityFewerAlertsDescription;

  /// No description provided for @hapticsSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Vibração'**
  String get hapticsSectionTitle;

  /// No description provided for @hapticsEnabledLabel.
  ///
  /// In pt, this message translates to:
  /// **'Usar vibração'**
  String get hapticsEnabledLabel;

  /// No description provided for @hapticsDescription.
  ///
  /// In pt, this message translates to:
  /// **'Alertas muito próximos usam duas vibrações curtas como reforço ao áudio.'**
  String get hapticsDescription;

  /// No description provided for @testHaptics.
  ///
  /// In pt, this message translates to:
  /// **'Testar vibração'**
  String get testHaptics;

  /// No description provided for @privacySectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Privacidade e sincronização'**
  String get privacySectionTitle;

  /// No description provided for @feedbackPrivacyDescription.
  ///
  /// In pt, this message translates to:
  /// **'O reconhecimento e os alertas funcionam localmente, sem enviar imagens. As preferências não contêm dados sensíveis e não são sincronizadas no MVP.'**
  String get feedbackPrivacyDescription;

  /// No description provided for @restoreDefaults.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar configurações padrão'**
  String get restoreDefaults;

  /// No description provided for @restoreDefaultsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar configurações?'**
  String get restoreDefaultsTitle;

  /// No description provided for @restoreDefaultsDescription.
  ///
  /// In pt, this message translates to:
  /// **'Velocidade, volume, alertas e vibração voltarão aos valores recomendados.'**
  String get restoreDefaultsDescription;

  /// No description provided for @cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @confirmRestore.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar'**
  String get confirmRestore;

  /// No description provided for @preferencesSaved.
  ///
  /// In pt, this message translates to:
  /// **'Configuração salva.'**
  String get preferencesSaved;

  /// No description provided for @defaultsRestored.
  ///
  /// In pt, this message translates to:
  /// **'Configurações padrão restauradas.'**
  String get defaultsRestored;

  /// No description provided for @voiceTestSucceeded.
  ///
  /// In pt, this message translates to:
  /// **'Teste de voz concluído.'**
  String get voiceTestSucceeded;

  /// No description provided for @hapticTestSucceeded.
  ///
  /// In pt, this message translates to:
  /// **'Teste de vibração concluído.'**
  String get hapticTestSucceeded;

  /// No description provided for @speechUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'A voz está indisponível. Verifique o mecanismo de síntese do aparelho e tente novamente.'**
  String get speechUnavailable;

  /// No description provided for @hapticsUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'A vibração não está disponível neste aparelho. Os avisos por voz continuam funcionando.'**
  String get hapticsUnavailable;

  /// No description provided for @preferencesSaveFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar a configuração. Tente novamente.'**
  String get preferencesSaveFailed;

  /// Telemetria local de diagnóstico da câmera, invisível ao TalkBack.
  ///
  /// In pt, this message translates to:
  /// **'{fps} FPS • recebidos: {received} • processados: {processed} • descartados: {dropped} • processamento: {processingMs} ms'**
  String cameraTelemetry(
    String fps,
    int received,
    int processed,
    int dropped,
    int processingMs,
  );
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
