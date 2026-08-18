import 'package:eyes_mobile/features/home/presentation/home_page.dart';
import 'package:eyes_mobile/features/not_found/presentation/not_found_page.dart';
import 'package:eyes_mobile/features/scanning/presentation/camera_diagnostics_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRoutes {
  static const String home = 'home';
  static const String camera = 'camera';
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
        name: AppRoutes.camera,
        path: '/camera',
        builder: (BuildContext context, GoRouterState state) =>
            const CameraDiagnosticsPage(),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
