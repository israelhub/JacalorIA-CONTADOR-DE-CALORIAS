import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/home/widgets/home_daily_goal_with_mascot.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('combina card de meta e mascote', (tester) async {
    await tester.pumpWidget(
      _wrap(
        HomeDailyGoalWithMascot(
          mascotAsset: 'assets/images/smiling green cartoon crocodile@2x.webp',
          records: [],
          selectedDate: DateTime(2026, 4, 2),
          userProfile: {'dailyCalorieGoal': 2689},
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-daily-goal-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-mascot-overlay')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-calorie-ring-value')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-daily-goal-explanation')),
      findsOneWidget,
    );
  });
}
