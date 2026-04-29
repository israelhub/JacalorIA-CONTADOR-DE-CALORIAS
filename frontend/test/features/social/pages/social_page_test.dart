import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jacaloria/features/social/models/social_group_models.dart';
import 'package:jacaloria/features/social/pages/social_page.dart';
import 'package:jacaloria/features/social/services/social_service.dart';

class _FakeSocialService extends SocialService {
  _FakeSocialService(this.groups);

  final List<SocialGroupSummary> groups;

  @override
  Future<List<SocialGroupSummary>> fetchGroups() async => groups;

  @override
  Future<SocialGroupDetail> fetchGroup(String groupId) async {
    final group = groups.firstWhere((group) => group.id == groupId);
    return SocialGroupDetail(
      group: group,
      ranking: const [],
      recentActivities: const [],
    );
  }
}

void main() {
  testWidgets('SocialPage mostra os grupos e o CTA de criação', (tester) async {
    final service = _FakeSocialService([
      SocialGroupSummary(
        id: 'group-1',
        name: 'Família Saudável',
        description: 'Bora se cuidar juntos!',
        iconKey: 'salad',
        competitionType: 'offensive',
        competitionLabel: 'Ofensiva',
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
      ),
    ]);

    await tester.pumpWidget(MaterialApp(home: SocialPage(service: service)));

    await tester.pumpAndSettle();

    expect(find.text('Social'), findsOneWidget);
    expect(find.text('Treine com seus amigos'), findsOneWidget);
    expect(find.text('Criar novo grupo'), findsWidgets);
    expect(find.text('Família Saudável'), findsOneWidget);
    expect(find.text('Mariana lidera'), findsOneWidget);
  });

  testWidgets('na tela vazia mostra apenas um CTA de criar grupo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: SocialPage(service: _FakeSocialService(const []))),
    );

    await tester.pumpAndSettle();

    expect(find.text('Criar novo grupo'), findsOneWidget);
    expect(find.text('Nenhum grupo por aqui ainda.'), findsOneWidget);
  });
}
