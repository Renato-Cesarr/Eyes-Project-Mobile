import 'package:eyes_mobile/features/home/domain/home_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class HomeController extends AsyncNotifier<HomeState> {
  @override
  Future<HomeState> build() async => const HomeState();

  void markFeedbackDelivered(String message) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }
    state = AsyncData<HomeState>(current.copyWith(feedbackMessage: message));
  }
}

final AsyncNotifierProvider<HomeController, HomeState> homeControllerProvider =
    AsyncNotifierProvider<HomeController, HomeState>(HomeController.new);
