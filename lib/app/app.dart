import 'package:eyes_mobile/app/routing/app_router.dart';
import 'package:eyes_mobile/app/theme/app_theme.dart';
import 'package:eyes_mobile/features/appearance/application/appearance_controller.dart';
import 'package:eyes_mobile/features/appearance/domain/appearance_preference.dart';
import 'package:eyes_mobile/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class EyesApp extends ConsumerWidget {
  const EyesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final appearance = ref
        .watch(appearanceControllerProvider)
        .asData
        ?.value
        .preference;
    final themeSelection = _themeSelection(
      appearance ?? AppearancePreference.system,
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      darkTheme: themeSelection.darkTheme,
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
      theme: themeSelection.theme,
      themeMode: themeSelection.mode,
    );
  }
}

({ThemeData theme, ThemeData darkTheme, ThemeMode mode}) _themeSelection(
  AppearancePreference preference,
) => switch (preference) {
  AppearancePreference.system => (
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    mode: ThemeMode.system,
  ),
  AppearancePreference.light => (
    theme: AppTheme.light,
    darkTheme: AppTheme.light,
    mode: ThemeMode.light,
  ),
  AppearancePreference.dark => (
    theme: AppTheme.dark,
    darkTheme: AppTheme.dark,
    mode: ThemeMode.dark,
  ),
  AppearancePreference.highContrastLight => (
    theme: AppTheme.highContrastLight,
    darkTheme: AppTheme.highContrastLight,
    mode: ThemeMode.light,
  ),
  AppearancePreference.highContrastDark => (
    theme: AppTheme.highContrastDark,
    darkTheme: AppTheme.highContrastDark,
    mode: ThemeMode.dark,
  ),
};
