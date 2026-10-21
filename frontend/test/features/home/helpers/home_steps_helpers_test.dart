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

    test('deduplica telefone e relogio no mesmo intervalo', () {
      final start = DateTime(2026, 10, 20, 10);
      final end = DateTime(2026, 10, 20, 10, 30);
      final total = resolveDedupedStepsTotal(
        [
          StepsIntervalSample(
            start: start,
            end: end,
            count: 2000,
            sourceKey: 'com.sec.android.app.shealth',
          ),
          StepsIntervalSample(
            start: start,
            end: end,
            count: 2100,
            sourceKey: 'com.sec.android.app.shealth',
          ),
        ],
        aggregateFallback: 4100,
      );

      expect(total, 2100);
    });

    test('soma intervalos sem sobreposicao', () {
      final morningStart = DateTime(2026, 10, 20, 8);
      final morningEnd = DateTime(2026, 10, 20, 9);
      final eveningStart = DateTime(2026, 10, 20, 18);
      final eveningEnd = DateTime(2026, 10, 20, 19);
      final total = resolveDedupedStepsTotal(
        [
          StepsIntervalSample(
            start: morningStart,
            end: morningEnd,
            count: 1200,
            sourceKey: 'com.sec.android.app.shealth',
          ),
          StepsIntervalSample(
            start: eveningStart,
            end: eveningEnd,
            count: 800,
            sourceKey: 'com.sec.android.app.shealth',
          ),
        ],
        aggregateFallback: 2000,
      );

      expect(total, 2000);
    });

    test('prioriza fonte Samsung quando ha outras fontes', () {
      final start = DateTime(2026, 10, 20, 10);
      final end = DateTime(2026, 10, 20, 11);
      final total = resolveDedupedStepsTotal(
        [
          StepsIntervalSample(
            start: start,
            end: end,
            count: 3000,
            sourceKey: 'com.sec.android.app.shealth',
          ),
          StepsIntervalSample(
            start: start,
            end: end,
            count: 5000,
            sourceKey: 'com.google.android.apps.fitness',
          ),
        ],
        aggregateFallback: 8000,
      );

      expect(total, 3000);
    });

    test('descarta metrica inflada em favor da estimativa', () {
      expect(
        pickStepsMetric(measured: 10, estimate: 5),
        closeTo(5, 0.001),
      );
      expect(
        pickStepsMetric(measured: 5.2, estimate: 5),
        closeTo(5.2, 0.001),
      );
    });
  });
}
