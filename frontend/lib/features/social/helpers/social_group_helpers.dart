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
    'goal_average' => 'Média de meta',
    _ => 'Sequência',
  };
}

({String displayValue, String label, IconData icon, Color iconColor}) socialRankingMetric({
  required String competitionType,
  required int points,
  required int streakDays,
}) {
  return switch (competitionType) {
    'daily_goal' => (
        displayValue: '$points',
        label: 'Metas',
        icon: Icons.flag_rounded,
        iconColor: AppColors.accent500,
      ),
    'xp' => (
        displayValue: '$points',
        label: 'XP',
        icon: Icons.bolt_rounded,
        iconColor: AppColors.missionsRewardGold,
      ),
    'goal_average' => (
        displayValue: points < 0 ? '—' : '$points',
        label: points < 0 ? 'sem dados' : 'média',
        icon: Icons.track_changes_rounded,
        iconColor: AppColors.accent500,
      ),
    _ => (
        displayValue: '$streakDays',
        label: 'Sequência',
        icon: Icons.local_fire_department_rounded,
        iconColor: AppColors.missionsRewardGold,
      ),
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
