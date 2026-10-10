import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/home/helpers/home_steps_helpers.dart';
import 'package:jacaloria/features/home/models/home_steps_models.dart';

void main() {
  group('home_steps_helpers', () {
    test('formata passos com separador de milhar', () {
      expect(formatStepsCount(0), '0');
      expect(formatStepsCount(999), '999');
      expect(formatStepsCount(1000), '1.000');
      expect(formatStepsCount(12345), '12.345');
    });

    test('limita meta diaria de passos', () {
      expect(clampDailyStepsGoal(100), minDailyStepsGoal);
      expect(clampDailyStepsGoal(10000), 10000);
      expect(clampDailyStepsGoal(999999), maxDailyStepsGoal);
    });

    test('restantes partem da meta e diminuem com os passos', () {
      const overview = HomeStepsOverview(steps: 4520, goalSteps: 10000);
      expect(overview.remainingSteps, 5480);
      expect(overview.remainingProgress, closeTo(0.548, 0.001));
    });

    test('estima distancia e calorias a partir dos passos', () {
      expect(
        estimateStepsDistanceKm(steps: 0, heightCm: 170),
        0,
      );
      expect(
        estimateStepsDistanceKm(steps: 10000, heightCm: 170),
        closeTo(7.055, 0.01),
      );
      expect(
        estimateStepsCaloriesKcal(steps: 10000, weightKg: 70),
        350,
      );
      expect(formatStepsDistanceKmNumber(0), '0');
      expect(formatStepsDistanceKmNumber(3.2), '3,20');
      expect(formatStepsDistanceKm(3.2), '3,20 km');
    });

    test('mensagem de status cobre os estados do card', () {
      expect(
        homeStepsStatusMessage(
          const HomeStepsOverview(status: HomeStepsStatus.needsPermission),
        ),
        'Ative o acesso aos passos',
      );
      expect(
        homeStepsStatusMessage(
          const HomeStepsOverview(
            status: HomeStepsStatus.ready,
            sourceLabel: 'Health Connect',
          ),
        ),
        'Health Connect',
      );
    });
  });
}
