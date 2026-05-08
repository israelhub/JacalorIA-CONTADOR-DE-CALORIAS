import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

String socialDurationLabel(int durationDays) {
  if (durationDays <= 0) return 'Infinito';
  return '$durationDays dias';
}

String socialRemainingDaysLabel(int remainingDays) {
  return '$remainingDays dias restantes';
}

String socialRemainingDaysLabelByGroup({
  required int remainingDays,
  required String competitionType,
  required bool isDefeated,
}) {
  if (competitionType == 'group_streak') {
    return isDefeated ? 'Sequência quebrada' : 'Infinito';
  }
  if (remainingDays <= 0) return 'Encerrado';
  return socialRemainingDaysLabel(remainingDays);
}

String socialCompetitionLabel(String competitionType) {
  return switch (competitionType) {
    'offensive' => 'Sequência',
    'daily_goal' => 'Meta diária',
    'xp' => 'XP',
    'group_streak' => 'Sequência dos amigos',
    _ => 'Sequência',
  };
}

IconData socialGroupIconData(String iconKey) {
  return switch (iconKey) {
    'salad' => Icons.eco_rounded,
    'muscle' => Icons.fitness_center_rounded,
    'fire' => Icons.local_fire_department_rounded,
    'trophy' => Icons.emoji_events_rounded,
    'rocket' => Icons.rocket_launch_rounded,
    'apple' => Icons.restaurant_rounded,
    'avocado' => Icons.favorite_rounded,
    _ => Icons.groups_rounded,
  };
}

String socialRelativeTimeLabel(DateTime createdAt) {
  final diff = DateTime.now().difference(createdAt);

  if (diff.inMinutes < 60) {
    final minutes = diff.inMinutes.clamp(1, 59);
    return 'há ${minutes}min';
  }

  if (diff.inHours < 24) {
    return 'há ${diff.inHours}h';
  }

  return 'há ${diff.inDays}d';
}

Color socialIconBackgroundColor() {
  return AppColors.missionsActionIconBg;
}
