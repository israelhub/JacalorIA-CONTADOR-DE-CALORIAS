import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jacaloria/features/social/models/social_group_models.dart';
import 'package:jacaloria/features/social/widgets/social_group_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('mostra tempo do desafio e dias restantes no card', (
    tester,
  ) async {
    final group = SocialGroupSummary.fromJson({
      'id': 'group-1',
      'name': 'Família Saudável',
      'description': 'Bora se cuidar juntos!',
      'iconKey': 'salad',
      'competitionType': 'offensive',
      'competitionLabel': 'Sequência',
      'memberCount': 4,
      'rankPosition': 2,
      'points': 18,
      'streakDays': 18,
      'leaderName': 'Mariana',
      'leaderLabel': 'Mariana lidera',
      'remainingDays': 3,
      'inviteCode': 'ABC123',
      'durationDays': 14,
    });

    await tester.pumpWidget(_wrap(SocialGroupCard(group: group)));

    expect(find.text('14 dias'), findsOneWidget);
    expect(find.text('3 dias restantes'), findsOneWidget);
    expect(find.text('Posição 2º'), findsOneWidget);
  });

  testWidgets('mostra Grupo finalizado e remove Encerrado quando finalizado', (
    tester,
  ) async {
    final group = SocialGroupSummary.fromJson({
      'id': 'group-2',
      'name': 'Desafio fechado',
      'description': 'Finalizado',
      'iconKey': 'salad',
      'competitionType': 'offensive',
      'competitionLabel': 'Sequência',
      'memberCount': 4,
      'rankPosition': 1,
      'points': 20,
      'streakDays': 4,
      'leaderName': 'Mariana',
      'leaderLabel': 'Mariana lidera',
      'remainingDays': 0,
      'inviteCode': 'XYZ123',
      'durationDays': 14,
    });

    await tester.pumpWidget(_wrap(SocialGroupCard(group: group, isFinished: true)));

    expect(find.text('Grupo finalizado'), findsOneWidget);
    expect(find.text('Encerrado'), findsNothing);
  });
}
