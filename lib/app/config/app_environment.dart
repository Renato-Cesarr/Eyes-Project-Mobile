import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppFlavor { dev, prod }

final class AppEnvironment {
  const AppEnvironment({
    required this.flavor,
    required this.apiBaseUrl,
    required this.enableVerboseLogs,
  });

  factory AppEnvironment.dev() => AppEnvironment(
    flavor: AppFlavor.dev,
    apiBaseUrl: Uri.parse(
      const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://10.0.2.2:8080',
      ),
    ),
    enableVerboseLogs: true,
  );

  factory AppEnvironment.prod() => AppEnvironment(
    flavor: AppFlavor.prod,
    apiBaseUrl: Uri.parse(
      const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api.example.invalid',
      ),
    ),
    enableVerboseLogs: false,
  );

  final Uri apiBaseUrl;
  final bool enableVerboseLogs;
  final AppFlavor flavor;

  bool get isProduction => flavor == AppFlavor.prod;
  String get label => flavor.name;
}

final Provider<AppEnvironment> appEnvironmentProvider =
    Provider<AppEnvironment>((Ref ref) {
      throw StateError('AppEnvironment must be overridden during bootstrap.');
    });
