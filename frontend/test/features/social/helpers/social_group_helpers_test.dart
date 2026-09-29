import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/social/helpers/social_group_helpers.dart';

void main() {
  group('socialFormatGoalAverageMetric', () {
    test('formata media/meta quando ha dados', () {
      expect(
        socialFormatGoalAverageMetric(
          averageCalories: 1800,
          dailyCalorieGoal: 2000,
        ),
        '1800/2000',
      );
    });

    test('formata media decimal com meta', () {
      expect(
        socialFormatGoalAverageMetric(
          averageCalories: 1884.5,
          dailyCalorieGoal: 2100,
        ),
        '1884.5/2100',
      );
    });

    test('mostra traco com meta quando nao ha media', () {
      expect(
        socialFormatGoalAverageMetric(
          averageCalories: -1,
          dailyCalorieGoal: 2000,
        ),
        '—/2000',
      );
    });

    test('mostra so media quando meta ausente', () {
      expect(
        socialFormatGoalAverageMetric(
          averageCalories: 1800,
          dailyCalorieGoal: null,
        ),
        '1800',
      );
    });
  });

  group('socialChatTimeLabel', () {
    test('mostra so o horario no mesmo dia', () {
      final now = DateTime.now();
      final at = DateTime(now.year, now.month, now.day, 9, 5);
      expect(socialChatTimeLabel(at), '09:05');
    });
  });

  group('socialChatTimestampLabel', () {
    test('mostra editada antes do horario', () {
      final at = DateTime(2026, 8, 19, 9, 5);
      expect(socialChatClockLabel(at), '09:05');
      expect(
        socialChatTimestampLabel(createdAt: at, isEdited: true),
        'editada 09:05',
      );
    });
  });

  group('socialChatCluster', () {
    test('primeira mensagem isolada mostra nome e avatar', () {
      final cluster = socialChatCluster(userId: 'ana');
      expect(cluster.showAvatar, isTrue);
      expect(cluster.showSenderName, isTrue);
      expect(cluster.isLastInGroup, isTrue);
    });

    test('mensagens seguidas do mesmo usuario compartilham o avatar', () {
      final first = socialChatCluster(
        userId: 'ana',
        nextUserId: 'ana',
      );
      final last = socialChatCluster(
        userId: 'ana',
        previousUserId: 'ana',
      );
      expect(first.showAvatar, isFalse);
      expect(first.showSenderName, isTrue);
      expect(first.isLastInGroup, isFalse);
      expect(last.showAvatar, isTrue);
      expect(last.showSenderName, isFalse);
      expect(last.isLastInGroup, isTrue);
    });

    test('quebra o grupo quando o remetente muda', () {
      final cluster = socialChatCluster(
        userId: 'ana',
        previousUserId: 'bruno',
        nextUserId: 'carla',
      );
      expect(cluster.showAvatar, isTrue);
      expect(cluster.showSenderName, isTrue);
      expect(cluster.isLastInGroup, isTrue);
    });
  });

  group('socialGroupPreviewActivities', () {
    test('mantem lista curta intacta', () {
      expect(socialGroupPreviewActivities(['a', 'b', 'c']), ['a', 'b', 'c']);
    });

    test('corta nas 3 mais recentes', () {
      expect(
        socialGroupPreviewActivities(['a', 'b', 'c', 'd', 'e']),
        ['a', 'b', 'c'],
      );
    });
  });

  group('socialGroupCanExpandActivities', () {
    test('mostra expansao quando o preview veio cheio', () {
      expect(
        socialGroupCanExpandActivities(
          expanded: false,
          hasMoreActivities: false,
          loadedCount: 3,
        ),
        isTrue,
      );
    });

    test('esconde expansao depois de abrir', () {
      expect(
        socialGroupCanExpandActivities(
          expanded: true,
          hasMoreActivities: true,
          loadedCount: 3,
        ),
        isFalse,
      );
    });
  });
}
