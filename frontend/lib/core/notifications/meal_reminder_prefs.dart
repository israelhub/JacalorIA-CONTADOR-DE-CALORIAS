import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/food_analysis/helpers/food_review_helpers.dart';
import 'meal_reminder_models.dart';

class MealReminderPrefs {
  MealReminderPrefs._();

  static const _masterKey = 'meal_reminders_master_enabled';
  static const _promptedKey = 'meal_reminders_permission_prompted';
  static const _listKey = 'meal_reminders_list_v2';

  // Chaves legadas (v1: 1 lembrete por FoodMealType).
  static String _legacyEnabledKey(FoodMealType type) =>
      'meal_reminders_${type.apiValue}_enabled';

  static String _legacyHourKey(FoodMealType type) =>
      'meal_reminders_${type.apiValue}_hour';

  static String _legacyMinuteKey(FoodMealType type) =>
      'meal_reminders_${type.apiValue}_minute';

  static Future<MealReminderSettings> load({
    SharedPreferences? preferences,
  }) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final defaults = MealReminderSettings.defaults();
    final rawList = prefs.getString(_listKey);

    List<MealReminderConfig> reminders;
    if (rawList != null && rawList.trim().isNotEmpty) {
      reminders = _decodeList(rawList);
    } else {
      reminders = _loadLegacyOrDefaults(prefs, defaults);
    }

    if (reminders.isEmpty) {
      reminders = defaults.reminders;
    }
    if (reminders.length > MealReminderSettings.maxReminders) {
      reminders = reminders.take(MealReminderSettings.maxReminders).toList();
    }

    return MealReminderSettings(
      masterEnabled: prefs.getBool(_masterKey) ?? defaults.masterEnabled,
      reminders: List<MealReminderConfig>.unmodifiable(reminders),
    );
  }

  static Future<void> save(
    MealReminderSettings settings, {
    SharedPreferences? preferences,
  }) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    await prefs.setBool(_masterKey, settings.masterEnabled);

    final clipped = settings.reminders.length > MealReminderSettings.maxReminders
        ? settings.reminders.take(MealReminderSettings.maxReminders)
        : settings.reminders;

    final encoded = jsonEncode(
      clipped.map((item) => item.toJson()).toList(growable: false),
    );
    await prefs.setString(_listKey, encoded);
  }

  static Future<bool> wasPermissionPrompted({
    SharedPreferences? preferences,
  }) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    return prefs.getBool(_promptedKey) ?? false;
  }

  static Future<void> markPermissionPrompted({
    SharedPreferences? preferences,
  }) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    await prefs.setBool(_promptedKey, true);
  }

  static List<MealReminderConfig> _decodeList(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <MealReminderConfig>[];
      }
      final items = <MealReminderConfig>[];
      final seenIds = <String>{};
      for (final entry in decoded) {
        if (entry is! Map) {
          continue;
        }
        final config = MealReminderConfig.fromJson(
          Map<String, dynamic>.from(entry),
        );
        if (seenIds.add(config.id)) {
          items.add(config);
        }
        if (items.length >= MealReminderSettings.maxReminders) {
          break;
        }
      }
      return items;
    } catch (_) {
      return const <MealReminderConfig>[];
    }
  }

  static List<MealReminderConfig> _loadLegacyOrDefaults(
    SharedPreferences prefs,
    MealReminderSettings defaults,
  ) {
    const legacyTypes = <FoodMealType>[
      FoodMealType.breakfast,
      FoodMealType.lunch,
      FoodMealType.dinner,
    ];

    final hasLegacy = legacyTypes.any(
      (type) =>
          prefs.containsKey(_legacyEnabledKey(type)) ||
          prefs.containsKey(_legacyHourKey(type)) ||
          prefs.containsKey(_legacyMinuteKey(type)),
    );
    if (!hasLegacy) {
      return defaults.reminders;
    }

    return legacyTypes.map((type) {
      final fallback = MealReminderConfig.defaultsForBuiltIn(type.apiValue);
      return MealReminderConfig(
        id: type.apiValue,
        title: fallback.title,
        enabled: prefs.getBool(_legacyEnabledKey(type)) ?? fallback.enabled,
        hour: prefs.getInt(_legacyHourKey(type)) ?? fallback.hour,
        minute: prefs.getInt(_legacyMinuteKey(type)) ?? fallback.minute,
      );
    }).toList(growable: false);
  }
}
