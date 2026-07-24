import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/profile/pages/profile_page.dart';
import 'package:jacaloria/features/profile/widgets/profile_achievements_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('hidrata peso, altura e selecoes do perfil', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const ProfilePage(
          initialProfile: {
            'weight': 78.4,
            'height': '181',
            'weightUnit': 'lb',
            'heightUnit': 'cm',
            'sex': 'Feminino',
            'objective': 'gainMass',
            'activityLevel': 'very',
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('78.4'), findsOneWidget);
    expect(find.textContaining('181'), findsOneWidget);
    expect(find.text('Feminino'), findsOneWidget);
    expect(find.text('Ganhar massa'), findsOneWidget);
    expect(find.text('Muito ativo'), findsOneWidget);
  });

  testWidgets('exibe objetivo maintainWeight em portugues', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const ProfilePage(
          initialProfile: {
            'objective': 'maintainWeight',
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Manter peso'), findsOneWidget);
    expect(find.text('Maintainweight'), findsNothing);
  });

  testWidgets('exibe objetivo loseWeight em portugues', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const ProfilePage(
          initialProfile: {
            'objective': 'loseWeight',
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Emagrecer'), findsOneWidget);
  });

  testWidgets('exibe objetivo gainMass em portugues', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const ProfilePage(
          initialProfile: {
            'objective': 'gainMass',
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Ganhar massa'), findsOneWidget);
  });

  testWidgets('exibe conquistas com missoes, recorde e visuais', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const ProfilePage(
          initialProfile: {
            'missionsCompleted': 31,
            'longestStreakDays': 12,
            'purchasedAvatarFrameIds': ['none', 'panda_bamboo'],
            'purchasedAvatarBackgroundIds': ['sky', 'pantano'],
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Conquistas'), findsOneWidget);
    expect(find.byType(ProfileAchievementMedal), findsNWidgets(3));
    expect(find.text('31'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });
}
