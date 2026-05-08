import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jacaloria/features/social/models/social_group_models.dart';
import 'package:jacaloria/features/social/pages/social_groups_tab_page.dart';

SocialGroupSummary _group() {
  return SocialGroupSummary(
    id: 'group-1',
    name: 'Família Saudável',
    description: 'Bora se cuidar juntos!',
    iconKey: 'salad',
    competitionType: 'offensive',
    competitionLabel: 'Sequência',
    durationDays: 7,
    durationDaysLabel: '7 dias',
    memberCount: 4,
    rankPosition: 2,
    points: 18,
    streakDays: 18,
    leaderName: 'Mariana',
    leaderLabel: 'Mariana lidera',
    remainingDays: 3,
    remainingDaysLabel: '3 dias',
    inviteCode: 'ABC123',
    activities: const [],
  );
}

void main() {
  testWidgets('mostra os botões Criar novo e Entrar lado a lado', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SocialGroupsTabPage(
            activeGroups: [_group()],
            historyGroups: const [],
            isGroupFinished: (_) => false,
            onCreateGroup: () {},
            onJoinGroup: () {},
            onOpenGroup: (_) {},
          ),
        ),
      ),
    );

    final createButton = find.text('Criar novo');
    final joinButton = find.text('Entrar');

    expect(find.text('Criar novo'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Seus grupos ativos'), findsOneWidget);
    expect(find.text('Família Saudável'), findsOneWidget);

    expect(
      (tester.getTopLeft(createButton).dy - tester.getTopLeft(joinButton).dy).abs(),
      lessThanOrEqualTo(1),
    );
    expect(tester.getTopLeft(createButton).dx, lessThan(tester.getTopLeft(joinButton).dx));
  });

  testWidgets('mantém o botão de criar grupo na tela vazia', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SocialGroupsTabPage(
            activeGroups: const [],
            historyGroups: const [],
            isGroupFinished: (_) => false,
            onCreateGroup: () {},
            onJoinGroup: () {},
            onOpenGroup: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Criar novo'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Nenhum grupo por aqui ainda'), findsOneWidget);
  });
}
