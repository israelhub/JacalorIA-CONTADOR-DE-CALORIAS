import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/performance/models/monthly_performance.dart';
import 'package:jacaloria/features/performance/models/weight_history.dart';
import 'package:jacaloria/features/performance/pages/performance_page.dart';
import 'package:jacaloria/features/performance/services/performance_service.dart';
import 'package:jacaloria/features/performance/widgets/performance_calendar.dart';
import 'package:jacaloria/shared/widgets/app_main_bottom_navigation.dart';

class _FakePerformanceService extends PerformanceService {
  @override
  Future<MonthlyPerformance> fetchMonthlyPerformance(DateTime month) async {
    return MonthlyPerformance(
      month: '2026-04',
      streakDays: 1,
      streakMessage: 'Continue!',
      calendarYear: month.year,
      calendarMonth: month.month,
      daysInMonth: 30,
      calendarDays: const [
        PerformanceCalendarDay(day: 1, status: PerformanceDayStatus.goalAchieved),
      ],
      metGoalDays: 1,
      elapsedDays: 1,
      registeredDays: 1,
      consistencyPercent: 100,
      avgDailyCalories: 1800,
      weightDeltaKg: -0.2,
      weightDifferenceKg: 0.2,
      weightDirection: 'lost',
      highlightTitle: 'Destaque',
      highlightDescription: 'Descricao',
      macroProgress: const [
        PerformanceMacroProgress(key: 'carbs', label: 'Carbo', percent: 50),
      ],
    );
  }

  @override
  Future<WeightHistory> fetchWeightHistory({
    String period = '30',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return WeightHistory(
      range: WeightHistoryRange(
        startDate: DateTime(2026, 4, 1),
        endDate: DateTime(2026, 4, 30),
        selectedPeriod: period,
      ),
      points: <WeightHistoryPoint>[
        WeightHistoryPoint(date: DateTime(2026, 4, 1), weight: 80),
        WeightHistoryPoint(date: DateTime(2026, 4, 30), weight: 79.8),
      ],
    );
  }
}

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('nao renderiza bottom navigation local', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PerformancePage(service: _FakePerformanceService()),
      ),
    );

    expect(find.byType(AppMainBottomNavigation), findsNothing);
  });

  testWidgets('encaminha a data do calendario quando um dia e tocado', (
    tester,
  ) async {
    DateTime? selectedDate;

    await tester.pumpWidget(
      _wrap(
        PerformancePage(
          service: _FakePerformanceService(),
          onDateSelected: (date) => selectedDate = date,
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(PerformanceCalendar),
        matching: find.text('1'),
      ).first,
    );
    await tester.pumpAndSettle();

    final now = DateTime.now();
    expect(selectedDate, DateTime(now.year, now.month, 1));
  });
}
