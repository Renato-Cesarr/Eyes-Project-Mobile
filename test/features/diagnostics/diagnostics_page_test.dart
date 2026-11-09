import 'package:eyes_mobile/app/theme/app_theme.dart';
import 'package:eyes_mobile/features/diagnostics/application/diagnostic_ports.dart';
import 'package:eyes_mobile/features/diagnostics/application/diagnostic_recorder.dart';
import 'package:eyes_mobile/features/diagnostics/presentation/diagnostics_page.dart';
import 'package:eyes_mobile/features/scanning/application/camera_gateway.dart';
import 'package:eyes_mobile/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'diagnostics_test.dart' show IdleCamera, MemoryExport, MemoryStore;

void main() {
  for (final enlarged in [false, true]) {
    testWidgets(
      'voluntary diagnostic flow, export and erase text200=$enlarged',
      (tester) async {
        tester.view.physicalSize = const Size(320, 850);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = enlarged ? 2 : 1;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });
        final store = MemoryStore();
        final exporter = MemoryExport();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              diagnosticsEnabledProvider.overrideWithValue(true),
              diagnosticStoreProvider.overrideWithValue(store),
              diagnosticExportProvider.overrideWithValue(exporter),
              cameraGatewayProvider.overrideWithValue(IdleCamera()),
            ],
            child: MaterialApp(
              theme: enlarged ? AppTheme.highContrastDark : AppTheme.light,
              locale: const Locale('pt', 'BR'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const DiagnosticsPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(store.value, isNull);
        final start = find.text('Iniciar diagnóstico');
        await tester.ensureVisible(start);
        await tester.tap(start);
        await tester.pumpAndSettle();
        expect(store.value, isNull);
        final checkbox = find.byType(Checkbox);
        await tester.ensureVisible(checkbox);
        await tester.tap(checkbox);
        await tester.pumpAndSettle();
        await tester.ensureVisible(start);
        await tester.tap(start);
        await tester.pumpAndSettle();
        expect(store.value, isNotNull);
        expect(find.text('Encerrar diagnóstico'), findsOneWidget);
        await tester.ensureVisible(find.text('Encerrar diagnóstico'));
        await tester.tap(find.text('Encerrar diagnóstico'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Compartilhar relatório'));
        await tester.tap(find.text('Compartilhar relatório'));
        await tester.pumpAndSettle();
        expect(exporter.shared, isNotNull);
        await tester.ensureVisible(find.text('Apagar relatório local'));
        await tester.tap(find.text('Apagar relatório local'));
        await tester.pumpAndSettle();
        expect(store.value, isNull);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
