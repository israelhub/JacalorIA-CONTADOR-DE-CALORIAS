import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/profile/pages/profile_page.dart';
import 'package:jacaloria/features/profile/widgets/profile_achievements_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

Future<void> _pumpProfile(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(_wrap(page));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('hidrata peso, altura e selecoes do perfil', (tester) async {
    await _pumpProfile(
      tester,
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
    );

    expect(find.textContaining('78.4'), findsOneWidget);
    expect(find.textContaining('181'), findsOneWidget);
    expect(find.text('Feminino'), findsOneWidget);
    expect(find.text('Ganhar massa'), findsOneWidget);
    expect(find.text('Muito ativo'), findsOneWidget);
  });

  testWidgets('exibe objetivo maintainWeight em portugues', (tester) async {
    await _pumpProfile(
      tester,
      const ProfilePage(initialProfile: {'objective': 'maintainWeight'}),
    );

    expect(find.text('Manter peso'), findsOneWidget);
    expect(find.text('Maintainweight'), findsNothing);
  });

  testWidgets('exibe objetivo loseWeight em portugues', (tester) async {
    await _pumpProfile(
      tester,
      const ProfilePage(initialProfile: {'objective': 'loseWeight'}),
    );

    expect(find.text('Emagrecer'), findsOneWidget);
  });

  testWidgets('exibe objetivo gainMass em portugues', (tester) async {
    await _pumpProfile(
      tester,
      const ProfilePage(initialProfile: {'objective': 'gainMass'}),
    );

    expect(find.text('Ganhar massa'), findsOneWidget);
  });

  testWidgets('exibe conquistas com missoes, recorde e visuais', (
    tester,
  ) async {
    await _pumpProfile(
      tester,
      const ProfilePage(
        initialProfile: {
          'missionsCompleted': 31,
          'longestStreakDays': 12,
          'purchasedAvatarFrameIds': ['none', 'panda_bamboo'],
          'purchasedAvatarBackgroundIds': ['sky', 'pantano'],
        },
      ),
    );

    expect(find.text('Conquistas'), findsOneWidget);
    expect(find.byType(ProfileAchievementMedal), findsNWidgets(3));
    expect(find.text('31'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('não exibe seletor de privacidade no perfil', (tester) async {
    await _pumpProfile(
      tester,
      const ProfilePage(initialProfile: {'missionsCompleted': 1}),
    );

    expect(find.text('Privacidade'), findsNothing);
    expect(find.text('Mostrar refeições no perfil público'), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('menu do perfil mantem editar e personalizar', (tester) async {
    await _pumpProfile(
      tester,
      const ProfilePage(initialProfile: {'name': 'Ana'}),
    );

    expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Personalizar perfil'), findsOneWidget);
    expect(find.text('Editar dados pessoais'), findsOneWidget);
    expect(find.text('Suporte'), findsNothing);
    expect(find.text('Lembretes de refeição'), findsNothing);
  });
}
