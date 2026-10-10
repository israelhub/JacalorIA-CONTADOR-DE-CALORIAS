import 'package:jacaloria/features/home/models/home_steps_models.dart';
import 'package:jacaloria/features/home/services/steps_service.dart';

class FakeStepsService extends StepsService {
  FakeStepsService({
    this.overview = const HomeStepsOverview(
      status: HomeStepsStatus.unsupported,
    ),
  });

  final HomeStepsOverview overview;

  @override
  Future<HomeStepsOverview> fetchToday({
    num? weightKg,
    num? heightCm,
    bool requestPermission = false,
  }) async {
    return overview;
  }

  @override
  Future<int> setDailyGoal(int goalSteps) async => goalSteps;

  @override
  Future<void> dispose() async {}
}
