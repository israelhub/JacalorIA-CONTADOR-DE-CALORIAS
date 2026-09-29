import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/profile/widgets/profile_achievements_card.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('exibe uma medalha por conquista com a quantidade', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const ProfileAchievementsCard(
          missionsCompleted: 27,
          longestStreakDays: 14,
          cosmeticsOwned: 5,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(ProfileAchievementMedal), findsNWidgets(3));
    expect(find.text('Missões completadas'), findsOneWidget);
    expect(find.text('Sequência mais alta'), findsOneWidget);
    expect(find.text('Visuais adquiridos'), findsOneWidget);
    expect(find.text('27'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('acomoda as tres medalhas em telas estreitas', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _wrap(
        const ProfileAchievementsCard(
          missionsCompleted: 128,
          longestStreakDays: 365,
          cosmeticsOwned: 10,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('128'), findsOneWidget);
    expect(find.text('365'), findsOneWidget);
  });

  testWidgets('mantem a medalha visivel quando a conquista esta zerada', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const ProfileAchievementsCard(
          missionsCompleted: 0,
          longestStreakDays: 0,
          cosmeticsOwned: 0,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('0'), findsNWidgets(3));
  });
}
