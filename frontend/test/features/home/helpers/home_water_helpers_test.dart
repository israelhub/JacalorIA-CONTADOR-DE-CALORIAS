import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/home/helpers/home_water_helpers.dart';

void main() {
  test('meta de agua usa 35 ml por kg com limites', () {
    expect(resolveDailyWaterGoalMl(), defaultDailyWaterGoalMl);
    expect(resolveDailyWaterGoalMl(weightKg: 70), 2450);
    expect(resolveDailyWaterGoalMl(weightKg: 40), minDailyWaterGoalMl);
    expect(resolveDailyWaterGoalMl(weightKg: 140), maxDailyWaterGoalMl);
  });

  test('formata volume em ml e litros', () {
    expect(formatWaterVolume(300), '300 ml');
    expect(formatWaterVolume(1000), '1 L');
    expect(formatWaterVolume(1500), '1,5 L');
  });

  test('preenche os 7 dias do grafico ate a data selecionada', () {
    final days = fillHomeWaterDays(
      selectedDate: DateTime(2026, 9, 27),
      millilitersByDate: const {'2026-09-27': 750, '2026-09-25': 400},
    );

    expect(days, hasLength(7));
    expect(days.first.date, DateTime(2026, 9, 21));
    expect(days.last.date, DateTime(2026, 9, 27));
    expect(days.last.milliliters, 750);
    expect(days[4].milliliters, 400);
  });
}
