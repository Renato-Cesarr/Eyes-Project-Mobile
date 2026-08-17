import 'package:eyes_mobile/app/routing/app_router.dart';
import 'package:eyes_mobile/app/theme/app_theme.dart';
import 'package:eyes_mobile/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class EyesApp extends ConsumerWidget {
  const EyesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      darkTheme: AppTheme.dark,
      highContrastDarkTheme: AppTheme.highContrastDark,
      highContrastTheme: AppTheme.highContrastLight,
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      onGenerateTitle: (BuildContext context) =>
          AppLocalizations.of(context).appName,
      routerConfig: router,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      themeMode: ThemeMode.system,
    );
  }
}
