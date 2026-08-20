import 'meal_reminder_models.dart';

class MealReminderWidgetSnapshot {
  const MealReminderWidgetSnapshot({
    required this.streakDays,
    required this.streakLabel,
    required this.messageTitle,
    required this.messageBody,
    this.reminder,
  });

  final int streakDays;
  final String streakLabel;
  final String messageTitle;
  final String messageBody;
  final MealReminderConfig? reminder;

  static const fallbackTitle = 'Hora de registrar';
  static const fallbackBody =
      'Que tal registrar uma refeição no JacalorIA?';

  Map<String, String> toWidgetData() {
    return <String, String>{
      'streak_days': '$streakDays',
      'streak_label': streakLabel,
      'message_title': messageTitle,
      'message_body': messageBody,
    };
  }
}

String mealReminderStreakLabel(int streakDays) {
  if (streakDays <= 0) {
    return 'Comece sua sequência hoje';
  }
  if (streakDays == 1) {
    return '1 dia de sequência';
  }
  return '$streakDays dias de sequência';
}

MealReminderConfig? activeMealReminder({
  required MealReminderSettings settings,
  required DateTime now,
}) {
  if (!settings.masterEnabled) {
    return null;
  }

  final enabled = settings.reminders.where((item) => item.enabled).toList()
    ..sort((left, right) {
      final byTime = left.minutesFromMidnight.compareTo(
        right.minutesFromMidnight,
      );
      if (byTime != 0) {
        return byTime;
      }
      return left.id.compareTo(right.id);
    });

  if (enabled.isEmpty) {
    return null;
  }

  final nowMinutes = now.hour * 60 + now.minute;
  for (var i = enabled.length - 1; i >= 0; i--) {
    if (enabled[i].minutesFromMidnight <= nowMinutes) {
      return enabled[i];
    }
  }
  return enabled.first;
}

MealReminderWidgetSnapshot buildMealReminderWidgetSnapshot({
  required MealReminderSettings settings,
  required int streakDays,
  required DateTime now,
}) {
  final reminder = activeMealReminder(settings: settings, now: now);
  final copy = reminder == null
      ? (title: MealReminderWidgetSnapshot.fallbackTitle, body: MealReminderWidgetSnapshot.fallbackBody)
      : mealReminderCopy(reminder);

  return MealReminderWidgetSnapshot(
    streakDays: streakDays < 0 ? 0 : streakDays,
    streakLabel: mealReminderStreakLabel(streakDays),
    messageTitle: copy.title,
    messageBody: copy.body,
    reminder: reminder,
  );
}
