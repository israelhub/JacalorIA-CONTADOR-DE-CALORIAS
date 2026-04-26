import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/missions/models/missions_overview.dart';

void main() {
  test('MissionsOverview.fromJson mapeia summary e secoes', () {
    final overview = MissionsOverview.fromJson({
      'summary': {'gold': 10, 'xp': 25},
      'intro': {
        'title': 'Bem-vindo às Missões!',
        'description': 'Descrição',
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
              'title': 'Atinja sua meta de proteínas',
              'description': 'Consuma 120g',
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
      ],
    });

    expect(overview.gold, 10);
    expect(overview.xp, 25);
    expect(overview.sections, hasLength(1));
    expect(overview.sections.first.id, MissionType.daily);
    expect(overview.sections.first.missions.first.accent, MissionAccent.action);
    expect(overview.sections.first.missions.first.progressPercent, 63);
  });
}
