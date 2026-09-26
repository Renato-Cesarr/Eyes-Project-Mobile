import 'package:eyes_mobile/app/app.dart';
import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:eyes_mobile/app/routing/app_router.dart';
import 'package:eyes_mobile/core/design_system/gallery/design_system_gallery_page.dart';
import 'package:eyes_mobile/features/not_found/presentation/not_found_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('development flavor exposes the component gallery', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        appEnvironmentProvider.overrideWithValue(AppEnvironment.dev()),
        designSystemGalleryEnabledProvider.overrideWithValue(true),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const EyesApp()),
    );
    container.read(appRouterProvider).go('/design-system');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(DesignSystemGalleryPage), findsOneWidget);
    expect(find.text('Eyes Design System 1.0'), findsOneWidget);
  });

  testWidgets('production flavor does not expose the component gallery', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        appEnvironmentProvider.overrideWithValue(AppEnvironment.prod()),
        designSystemGalleryEnabledProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const EyesApp()),
    );
    container.read(appRouterProvider).go('/design-system');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(NotFoundPage), findsOneWidget);
    expect(find.byType(DesignSystemGalleryPage), findsNothing);
  });
}
