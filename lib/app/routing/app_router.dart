import 'package:eyes_mobile/features/assistive_feedback/presentation/feedback_settings_page.dart';
import 'package:eyes_mobile/features/help/presentation/help_and_safety_page.dart';
import 'package:eyes_mobile/features/home/presentation/home_page.dart';
import 'package:eyes_mobile/features/not_found/presentation/not_found_page.dart';
import 'package:eyes_mobile/features/scanning/presentation/assistive_scan_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRoutes {
  static const String home = 'home';
  static const String camera = 'camera';
  static const String settings = 'settings';
  static const String help = 'help';
}

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  final router = GoRouter(
    errorBuilder: (BuildContext context, GoRouterState state) =>
        const NotFoundPage(),
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        name: AppRoutes.home,
        path: '/',
        builder: (BuildContext context, GoRouterState state) =>
            const HomePage(),
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
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
