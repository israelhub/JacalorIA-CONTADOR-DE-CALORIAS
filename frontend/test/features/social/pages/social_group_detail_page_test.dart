import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jacaloria/features/social/models/social_group_models.dart';
import 'package:jacaloria/features/social/pages/social_group_detail_page.dart';
import 'package:jacaloria/features/social/services/social_service.dart';

class _FakeSocialService extends SocialService {
  _FakeSocialService(this.detail);

  final SocialGroupDetail detail;

  @override
  Future<SocialGroupDetail> fetchGroup(String groupId) async => detail;
}

void main() {
  testWidgets('abre o modal de edicao com os dados do grupo', (tester) async {
    final detail = SocialGroupDetail(
      group: SocialGroupSummary.fromJson({
        'id': 'group-1',
        'name': 'Família Saudável',
        'description': 'Bora se cuidar juntos!',
        'iconKey': 'salad',
        'competitionType': 'offensive',
        'competitionLabel': 'Ofensiva',
        'durationDays': 14,
        'memberCount': 4,
        'rankPosition': 2,
        'points': 18,
        'streakDays': 18,
        'leaderName': 'Mariana',
        'leaderLabel': 'Mariana lidera',
        'remainingDays': 3,
        'inviteCode': 'ABC123',
      }),
      ranking: const [],
      recentActivities: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SocialGroupDetailPage(
          groupId: 'group-1',
          initialDetail: detail,
          service: _FakeSocialService(detail),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Editar grupo'), findsOneWidget);
    expect(find.text('14 dias'), findsWidgets);
    expect(find.byKey(const ValueKey('social-duration-14')), findsOneWidget);
  });
}
