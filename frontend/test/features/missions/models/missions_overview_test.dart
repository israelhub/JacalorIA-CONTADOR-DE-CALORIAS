import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/missions/models/missions_overview.dart';

void main() {
  test('MissionsOverview.fromJson mapeia summary, evento e secoes', () {
    final overview = MissionsOverview.fromJson({
      'summary': {'gold': 10, 'xp': 25},
      'intro': {
        'title': 'Bem-vindo às Missões!',
        'description': 'Descrição',
      },
      'weekendEvent': {
        'active': true,
        'title': 'Missão do fim de semana',
        'headline': 'Que bom ver você de novo!',
        'subtitle': 'Complete o desafio',
        'remainingDays': 2,
        'remainingLabel': '2 DIAS',
      },
      'checkIn': {
        'active': true,
        'campaignId': 'aug2026',
        'title': 'Recompensas de agosto',
        'subtitle': 'Ganhe recompensas até o fim de agosto',
        'endsOnLabel': 'até 31/08',
        'todayDayKey': '2026-08-15',
        'canClaimToday': true,
        'claimedToday': false,
        'days': [
          {
            'dayKey': '2026-08-15',
            'dayIndex': 1,
            'label': 'Dia 15',
            'status': 'claimable',
            'primaryKind': 'gold',
            'rewardSummary': '15 ouro',
            'rewards': [
              {'kind': 'gold', 'amount': 15},
            ],
          },
        ],
      },
      'sections': [
        {
          'id': 'daily',
          'title': 'Missões diárias',
          'subtitle': 'Renovam à meia-noite',
          'missions': [
            {
              'id': '1',
              'key': 'daily_protein_goal',
              'type': 'daily',
              'title': 'Atinja sua meta diária de proteínas',
              'description': 'Atinja sua meta diária de proteínas',
              'accent': 'action',
              'progressCurrent': 75,
              'progressTarget': 120,
              'progressLabel': '75/120',
              'progressPercent': 63,
              'rewardGold': 20,
              'rewardXp': 40,
            },
          ],
        },
        {
          'id': 'weekend',
          'title': 'Missão do fim de semana',
          'subtitle': 'Sexta, sábado e domingo',
          'missions': [
            {
              'id': '2',
              'key': 'weekend_goal_trio',
              'type': 'weekend',
              'title': 'Bata a meta diária na sexta, sábado e domingo',
              'description': 'Bata a meta diária na sexta, sábado e domingo',
              'accent': 'challenge',
              'progressCurrent': 1,
              'progressTarget': 3,
              'progressLabel': '1/3',
              'progressPercent': 33,
              'rewardGold': 120,
              'rewardXp': 240,
            },
          ],
        },
      ],
    });

    expect(overview.gold, 10);
    expect(overview.xp, 25);
    expect(overview.weekendEvent.active, isTrue);
    expect(overview.weekendEvent.remainingLabel, '2 DIAS');
    expect(overview.checkIn.active, isTrue);
    expect(overview.checkIn.canClaimToday, isTrue);
    expect(overview.checkIn.days, hasLength(1));
    expect(overview.checkIn.days.first.primaryKind, CheckInRewardKind.gold);
    expect(overview.sections, hasLength(2));
    expect(overview.sections.first.id, MissionType.daily);
    expect(overview.sections.first.missions.first.accent, MissionAccent.action);
    expect(overview.sections.first.missions.first.progressPercent, 63);
    expect(overview.sections[1].id, MissionType.weekend);
    expect(overview.sections[1].missions.first.rewardGold, 120);
  });
}
