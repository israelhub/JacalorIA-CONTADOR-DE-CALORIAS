import 'package:flutter_test/flutter_test.dart';

import 'package:jacaloria/features/social/models/social_group_detail.dart';

void main() {
  Map<String, dynamic> _groupJson() => {
        'id': 'g1',
        'name': 'Família',
        'description': '',
        'iconKey': 'salad',
        'competitionType': 'offensive',
        'durationDays': 7,
        'memberCount': 1,
        'rankPosition': 1,
        'points': 0,
        'streakDays': 0,
        'leaderName': 'Eu',
        'remainingDays': 4,
        'inviteCode': 'ABC123',
      };

  Map<String, dynamic> _activityJson(String id) => {
        'id': id,
        'message': 'Atividade $id',
        'activityType': 'joined',
        'createdAt': '2026-08-19T12:00:00.000Z',
      };

  test('marca hasMoreActivities pelo flag da API', () {
    final detail = SocialGroupDetail.fromJson({
      'group': _groupJson(),
      'ranking': const [],
      'recentActivities': [
        _activityJson('a1'),
        _activityJson('a2'),
        _activityJson('a3'),
      ],
      'hasMoreActivities': true,
    });

    expect(detail.hasMoreActivities, isTrue);
    expect(detail.recentActivities, hasLength(3));
  });

  test('infere hasMoreActivities quando o payload traz mais de 3 itens', () {
    final detail = SocialGroupDetail.fromJson({
      'group': _groupJson(),
      'ranking': const [],
      'recentActivities': [
        _activityJson('a1'),
        _activityJson('a2'),
        _activityJson('a3'),
        _activityJson('a4'),
      ],
    });

    expect(detail.hasMoreActivities, isTrue);
    expect(detail.recentActivities, hasLength(4));
  });
}
