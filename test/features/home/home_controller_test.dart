import 'package:eyes_mobile/features/home/application/home_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('publishes a message in the live region after feedback', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(homeControllerProvider.future);
    container
        .read(homeControllerProvider.notifier)
        .markFeedbackDelivered('Feedback confirmado.');

    expect(
      container.read(homeControllerProvider).value?.feedbackMessage,
      'Feedback confirmado.',
    );
  });
}
