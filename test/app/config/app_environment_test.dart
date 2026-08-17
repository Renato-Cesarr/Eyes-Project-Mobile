import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates reproducible development and production environments', () {
    final development = AppEnvironment.dev();
    final production = AppEnvironment.prod();

    expect(development.flavor, AppFlavor.dev);
    expect(development.apiBaseUrl, Uri.parse('http://10.0.2.2:8080'));
    expect(development.enableVerboseLogs, isTrue);
    expect(development.isProduction, isFalse);
    expect(development.label, 'dev');

    expect(production.flavor, AppFlavor.prod);
    expect(production.apiBaseUrl, Uri.parse('https://api.example.invalid'));
    expect(production.enableVerboseLogs, isFalse);
    expect(production.isProduction, isTrue);
    expect(production.label, 'prod');
  });

  test('requires the environment provider to be overridden', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      () => container.read(appEnvironmentProvider),
      throwsA(
        predicate<Object>(
          (Object error) => error.toString().contains(
            'AppEnvironment must be overridden during bootstrap.',
          ),
        ),
      ),
    );
  });

  test('exposes an explicitly overridden environment', () {
    final environment = AppEnvironment.dev();
    final container = ProviderContainer(
      overrides: [appEnvironmentProvider.overrideWithValue(environment)],
    );
    addTearDown(container.dispose);

    expect(container.read(appEnvironmentProvider), same(environment));
  });
}
