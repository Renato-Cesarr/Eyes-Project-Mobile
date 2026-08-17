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
}
