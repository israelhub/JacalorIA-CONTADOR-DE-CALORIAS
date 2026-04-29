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
      'competitionLabel': 'Ofensiva',
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
    expect(find.text('#2'), findsOneWidget);
  });
}