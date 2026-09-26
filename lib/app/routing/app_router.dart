import 'package:eyes_mobile/core/design_system/gallery/design_system_gallery_page.dart';
import 'package:eyes_mobile/features/account/presentation/account_page.dart';
import 'package:eyes_mobile/features/assistive_feedback/presentation/feedback_settings_page.dart';
import 'package:eyes_mobile/features/help/presentation/help_and_safety_page.dart';
import 'package:eyes_mobile/features/home/presentation/home_page.dart';
import 'package:eyes_mobile/features/not_found/presentation/not_found_page.dart';
import 'package:eyes_mobile/features/onboarding/presentation/app_entry_page.dart';
import 'package:eyes_mobile/features/onboarding/presentation/onboarding_page.dart';
import 'package:eyes_mobile/features/scanning/presentation/assistive_scan_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRoutes {
  static const String account = 'account';
  static const String entry = 'entry';
  static const String home = 'home';
  static const String onboarding = 'onboarding';
  static const String camera = 'camera';
  static const String settings = 'settings';
  static const String help = 'help';
  static const String designSystem = 'design-system';
}

final Provider<bool> designSystemGalleryEnabledProvider = Provider<bool>(
  (Ref ref) => false,
);

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  final galleryEnabled = ref.watch(designSystemGalleryEnabledProvider);
  final router = GoRouter(
    errorBuilder: (BuildContext context, GoRouterState state) =>
        const NotFoundPage(),
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        name: AppRoutes.entry,
        path: '/',
        builder: (BuildContext context, GoRouterState state) =>
            const AppEntryPage(),
      ),
      GoRoute(
        name: AppRoutes.home,
        path: '/home',
        builder: (BuildContext context, GoRouterState state) =>
            const HomePage(),
      ),
      GoRoute(
        name: AppRoutes.onboarding,
        path: '/onboarding',
        builder: (BuildContext context, GoRouterState state) => OnboardingPage(
          replay: state.uri.queryParameters['replay'] == 'true',
        ),
      ),
      GoRoute(
        name: AppRoutes.account,
        path: '/account',
        builder: (BuildContext context, GoRouterState state) => AccountPage(
          returnToOnboarding:
              state.uri.queryParameters['source'] == 'onboarding',
        ),
      ),
      GoRoute(
        name: AppRoutes.help,
        path: '/help',
        builder: (BuildContext context, GoRouterState state) =>
            const HelpAndSafetyPage(),
      ),
      GoRoute(
        name: AppRoutes.settings,
        path: '/settings',
        builder: (BuildContext context, GoRouterState state) =>
            const FeedbackSettingsPage(),
      ),
      GoRoute(
        name: AppRoutes.camera,
        path: '/camera',
        builder: (BuildContext context, GoRouterState state) =>
            const AssistiveScanPage(),
      ),
      if (galleryEnabled)
        GoRoute(
          name: AppRoutes.designSystem,
          path: '/design-system',
          builder: (BuildContext context, GoRouterState state) =>
              const DesignSystemGalleryPage(),
        ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
