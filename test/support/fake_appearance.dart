import 'package:eyes_mobile/features/appearance/application/appearance_repository.dart';
import 'package:eyes_mobile/features/appearance/domain/appearance_preference.dart';

final class InMemoryAppearanceRepository implements AppearanceRepository {
  InMemoryAppearanceRepository({
    this.preference = AppearancePreference.system,
    this.failure,
  });

  AppearancePreference preference;
  Object? failure;
  var saveCalls = 0;

  @override
  Future<AppearancePreference> load() async {
    if (failure case final failure?) {
      throw failure;
    }
    return preference;
  }

  @override
  Future<void> save(AppearancePreference preference) async {
    if (failure case final failure?) {
      throw failure;
    }
    saveCalls++;
    this.preference = preference;
  }
}
