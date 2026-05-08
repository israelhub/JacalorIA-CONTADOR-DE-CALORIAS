import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jacaloria/features/social/models/social_group_models.dart';
import 'package:jacaloria/features/social/services/social_service.dart';
import 'package:jacaloria/features/social/widgets/social_create_group_sheet.dart';
import 'package:jacaloria/shared/theme/app_theme.dart';

class _FakeSocialService extends SocialService {
  String? name;
  String? description;
  String? competitionType;
  String? iconKey;
  int? durationDays;
  bool? isPublic;
  List<String>? memberUserIds;

  @override
  Future<SocialGroupDetail> createGroup({
    required String name,
    required String description,
    required String competitionType,
    required String iconKey,
    int durationDays = 7,
    List<String> memberUserIds = const [],
    bool isPublic = false,
  }) async {
    this.name = name;
    this.description = description;
    this.competitionType = competitionType;
    this.iconKey = iconKey;
    this.durationDays = durationDays;
    this.isPublic = isPublic;
    this.memberUserIds = memberUserIds;

    return SocialGroupDetail(
      group: SocialGroupSummary(
        id: 'group-1',
        name: name,
        description: description,
        iconKey: iconKey,
        competitionType: competitionType,
        competitionLabel: 'Sequência',
        durationDays: durationDays,
        durationDaysLabel: '$durationDays dias',
        memberCount: 1,
        rankPosition: 1,
        points: 0,
        streakDays: 0,
        leaderName: 'Você',
        leaderLabel: 'Você lidera',
        remainingDays: durationDays,
        remainingDaysLabel: '$durationDays dias restantes',
        inviteCode: 'ABC123',
        activities: const [],
      ),
      ranking: const [],
      recentActivities: const [],
    );
  }
}

void main() {
  testWidgets('permite escolher a duracao do desafio ao criar grupo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SocialCreateGroupSheet(service: _FakeSocialService())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Tempo do desafio'), findsOneWidget);
    expect(find.text('7 dias'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('social-duration-14')));
    await tester.pumpAndSettle();

    final chip = tester.widget<Container>(
      find.byKey(const ValueKey('social-duration-14')),
    );
    final decoration = chip.decoration as BoxDecoration;

    expect(decoration.color, isNot(AppColors.surfaceAlt));
  });
}
