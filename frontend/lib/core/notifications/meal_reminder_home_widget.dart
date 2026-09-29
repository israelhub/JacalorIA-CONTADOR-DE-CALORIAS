import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import 'meal_reminder_models.dart';
import 'meal_reminder_prefs.dart';
import 'meal_reminder_widget_snapshot.dart';

class MealReminderHomeWidget {
  MealReminderHomeWidget._();

  static const androidProvider = 'MealReminderWidgetProvider';
  static const androidQualifiedName =
      'com.jacaloria.app.MealReminderWidgetProvider';

  static bool get isSupported {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android;
  }

  static Future<void> sync({
    MealReminderSettings? settings,
    int? streakDays,
    DateTime? now,
  }) async {
    if (!isSupported) {
      return;
    }

    try {
      final resolvedSettings = settings ?? await MealReminderPrefs.load();
      var resolvedStreak = streakDays;
      if (resolvedStreak == null) {
        final saved = await HomeWidget.getWidgetData<String>('streak_days');
        resolvedStreak = int.tryParse(saved ?? '') ?? 0;
      }
      final snapshot = buildMealReminderWidgetSnapshot(
        settings: resolvedSettings,
        streakDays: resolvedStreak,
        now: now ?? DateTime.now(),
      );

      final remindersJson = jsonEncode(
        (resolvedSettings.reminders.where((item) => item.enabled).toList()
              ..sort(
                (left, right) => left.minutesFromMidnight.compareTo(
                  right.minutesFromMidnight,
                ),
              ))
            .map((item) {
              final copy = mealReminderCopy(item);
              return <String, dynamic>{
                'hour': item.hour,
                'minute': item.minute,
                'title': copy.title,
                'body': copy.body,
              };
            })
            .toList(growable: false),
      );

      await HomeWidget.saveWidgetData<String>(
        'streak_days',
        '${snapshot.streakDays}',
      );
      await HomeWidget.saveWidgetData<String>(
        'streak_label',
        snapshot.streakLabel,
      );
      await HomeWidget.saveWidgetData<String>(
        'message_title',
        snapshot.messageTitle,
      );
      await HomeWidget.saveWidgetData<String>(
        'message_body',
        snapshot.messageBody,
      );
      await HomeWidget.saveWidgetData<String>(
        'master_enabled',
        resolvedSettings.masterEnabled ? '1' : '0',
      );
      await HomeWidget.saveWidgetData<String>(
        'reminders_json',
        remindersJson,
      );
      await HomeWidget.saveWidgetData<String>(
        'fallback_title',
        MealReminderWidgetSnapshot.fallbackTitle,
      );
      await HomeWidget.saveWidgetData<String>(
        'fallback_body',
        MealReminderWidgetSnapshot.fallbackBody,
      );

      await HomeWidget.updateWidget(
        androidName: androidProvider,
        qualifiedAndroidName: androidQualifiedName,
      );
    } catch (_) {}
  }

  static Future<void> clear() async {
    if (!isSupported) {
      return;
    }

    try {
      await HomeWidget.saveWidgetData<String>('streak_days', '0');
      await HomeWidget.saveWidgetData<String>(
        'streak_label',
        mealReminderStreakLabel(0),
      );
      await HomeWidget.saveWidgetData<String>(
        'message_title',
        MealReminderWidgetSnapshot.fallbackTitle,
      );
      await HomeWidget.saveWidgetData<String>(
        'message_body',
        MealReminderWidgetSnapshot.fallbackBody,
      );
      await HomeWidget.saveWidgetData<String>('master_enabled', '0');
      await HomeWidget.saveWidgetData<String>('reminders_json', '[]');
      await HomeWidget.updateWidget(
        androidName: androidProvider,
        qualifiedAndroidName: androidQualifiedName,
      );
    } catch (_) {}
  }
}
