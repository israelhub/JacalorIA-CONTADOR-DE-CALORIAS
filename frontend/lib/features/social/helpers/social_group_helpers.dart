import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import 'social_model_parsers.dart';

const socialGroupActivityPreviewLimit = 3;

List<T> socialGroupPreviewActivities<T>(List<T> activities) {
  if (activities.length <= socialGroupActivityPreviewLimit) {
    return activities;
  }
  return activities.sublist(0, socialGroupActivityPreviewLimit);
}

bool socialGroupCanExpandActivities({
  required bool expanded,
  required bool hasMoreActivities,
  required int loadedCount,
}) {
  if (expanded) return false;
  return hasMoreActivities || loadedCount >= socialGroupActivityPreviewLimit;
}

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

String socialCompetitionRule(String competitionType) {
  return switch (competitionType) {
    'offensive' =>
      'Registre as refeições todos os dias. Ganha quem mantiver a sequência mais longa.',
    'daily_goal' =>
      'Tente bater a sua meta de calorias todo dia. Ganha quem acertar mais vezes.',
    'goal_average' =>
      'Acompanhe sua meta de calorias ao longo do desafio. Ganha quem ficar mais perto.',
    'xp' => 'Complete missões para ganhar XP. Ganha quem juntar mais pontos.',
    'group_streak' =>
      'Todos precisam registrar as refeições no dia. Se alguém pular, o desafio acaba.',
    _ =>
      'Registre as refeições todos os dias. Ganha quem mantiver a sequência mais longa.',
  };
}

({String displayValue, String label, IconData icon, Color iconColor})
socialRankingMetric({
  required String competitionType,
  required num points,
  required int streakDays,
  int? dailyCalorieGoal,
}) {
  return switch (competitionType) {
    'daily_goal' => (
      displayValue: '${points.round()}',
      label: 'Metas',
      icon: Icons.flag_rounded,
      iconColor: AppColors.accent500,
    ),
    'xp' => (
      displayValue: '${points.round()}',
      label: 'XP',
      icon: Icons.bolt_rounded,
      iconColor: AppColors.missionsRewardGold,
    ),
    'goal_average' => (
      displayValue: socialFormatGoalAverageMetric(
        averageCalories: points,
        dailyCalorieGoal: dailyCalorieGoal,
      ),
      label: points < 0 ? 'sem dados' : 'média/meta',
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

String socialFormatGoalAverageMetric({
  required num averageCalories,
  int? dailyCalorieGoal,
}) {
  final goal = dailyCalorieGoal != null && dailyCalorieGoal > 0
      ? dailyCalorieGoal.round().toString()
      : null;
  if (averageCalories < 0) {
    return goal == null ? '—' : '—/$goal';
  }
  final average = socialFormatAverageCalories(averageCalories);
  return goal == null ? average : '$average/$goal';
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

String socialChatClockLabel(DateTime createdAt) {
  final local = createdAt.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String socialChatTimeLabel(DateTime createdAt) {
  final local = createdAt.toLocal();
  final now = DateTime.now();
  final time = socialChatClockLabel(createdAt);
  if (local.year == now.year &&
      local.month == now.month &&
      local.day == now.day) {
    return time;
  }
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} $time';
}

String socialChatTimestampLabel({
  required DateTime createdAt,
  required bool isEdited,
}) {
  final time = socialChatClockLabel(createdAt);
  return isEdited ? 'editada $time' : time;
}

({bool showAvatar, bool showSenderName, bool isLastInGroup}) socialChatCluster({
  required String userId,
  String? previousUserId,
  String? nextUserId,
}) {
  final samePrevious =
      previousUserId != null &&
      previousUserId.isNotEmpty &&
      previousUserId == userId;
  final sameNext =
      nextUserId != null && nextUserId.isNotEmpty && nextUserId == userId;
  return (
    showAvatar: !sameNext,
    showSenderName: !samePrevious,
    isLastInGroup: !sameNext,
  );
}

Color socialIconBackgroundColor() {
  return AppColors.missionsActionIconBg;
}
