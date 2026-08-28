import 'package:eyes_mobile/features/help/presentation/help_and_safety_page.dart';
import 'package:eyes_mobile/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('explains safe, private and accessible scan usage', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpPage(tester);

    expect(find.text('Ajuda e segurança'), findsOneWidget);
    expect(find.text('Uso seguro'), findsOneWidget);
    expect(
      find.textContaining('não substitui bengala, cão-guia'),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(find.text('Uso seguro')).flagsCollection.isHeader,
      isTrue,
    );

    await tester.scrollUntilVisible(
      find.text('Privacidade'),
      180,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Privacidade'), findsOneWidget);
    expect(find.textContaining('processadas localmente'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Como usar a varredura'),
      180,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Como usar a varredura'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Permissão da câmera'),
      180,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Permissão da câmera'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('keeps every safety section reachable at 200 percent text', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpPage(tester);

    final permission = find.text('Permissão da câmera');
    await tester.scrollUntilVisible(
      permission,
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(permission, findsOneWidget);
  });
}

Future<void> _pumpPage(WidgetTester tester) {
  return tester.pumpWidget(
    const MaterialApp(
      locale: Locale('pt', 'BR'),
      localizationsDelegates: <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: HelpAndSafetyPage(),
    ),
  );
}
