final class HomeState {
  const HomeState({this.feedbackMessage});

  final String? feedbackMessage;

  HomeState copyWith({String? feedbackMessage}) {
    return HomeState(feedbackMessage: feedbackMessage ?? this.feedbackMessage);
  }
}
