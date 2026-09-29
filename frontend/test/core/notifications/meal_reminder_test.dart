import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:jacaloria/core/notifications/meal_reminder_models.dart';
import 'package:jacaloria/core/notifications/meal_reminder_prefs.dart';
import 'package:jacaloria/core/notifications/meal_reminder_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('MealReminderSettings defaults', () {
    test('liga café, almoço e jantar em horários próximos ao comum', () {
      final settings = MealReminderSettings.defaults();

      expect(settings.masterEnabled, isTrue);
      expect(settings.reminders, hasLength(3));
      expect(settings.byId(MealReminderDefaults.breakfastId)?.hour, 7);
      expect(settings.byId(MealReminderDefaults.breakfastId)?.minute, 45);
      expect(settings.byId(MealReminderDefaults.lunchId)?.hour, 11);
      expect(settings.byId(MealReminderDefaults.dinnerId)?.hour, 18);
      expect(settings.canAddMore, isTrue);
      expect(settings.remainingSlots, 3);
    });

    test('gera copy em português por refeição', () {
      expect(
        mealReminderCopy(
          MealReminderConfig.defaultsForBuiltIn(
            MealReminderDefaults.breakfastId,
          ),
        ).title,
        contains('café'),
      );
      expect(
        mealReminderCopy(
          MealReminderConfig.defaultsForBuiltIn(MealReminderDefaults.lunchId),
        ).title,
        contains('almoço'),
      );
      expect(
        mealReminderCopy(
          MealReminderConfig.defaultsForBuiltIn(MealReminderDefaults.dinnerId),
        ).title,
        contains('jantar'),
      );
    });

    test('permite adicionar até 6 lembretes e bloqueia o 7º', () {
      var settings = MealReminderSettings.defaults();
      for (var i = 0; i < 3; i++) {
        final next = settings.tryAdd(
          MealReminderConfig.custom(
            hour: 10 + i,
            minute: 0,
            id: 'custom_$i',
            title: 'Extra $i',
          ),
        );
        expect(next, isNotNull);
        settings = next!;
      }

      expect(settings.reminders, hasLength(6));
      expect(settings.canAddMore, isFalse);
      expect(
        settings.tryAdd(
          MealReminderConfig.custom(hour: 16, minute: 0, id: 'overflow'),
        ),
        isNull,
      );
    });

    test('remove lembrete pelo id', () {
      final settings = MealReminderSettings.defaults().withoutReminder(
        MealReminderDefaults.lunchId,
      );
      expect(settings.reminders, hasLength(2));
      expect(settings.byId(MealReminderDefaults.lunchId), isNull);
      expect(settings.canAddMore, isTrue);
    });
  });

  group('MealReminderPrefs', () {
    test('persiste lista com lembretes extras', () async {
      final updated = MealReminderSettings.defaults()
          .tryAdd(
            MealReminderConfig.custom(
              hour: 15,
              minute: 30,
              id: 'custom_snack',
              title: 'Lanche',
            ),
          )!
          .withReminder(
            const MealReminderConfig(
              id: MealReminderDefaults.lunchId,
              title: 'Almoço',
              enabled: false,
              hour: 12,
              minute: 30,
            ),
          )
          .copyWith(masterEnabled: false);

      await MealReminderPrefs.save(updated);
      final loaded = await MealReminderPrefs.load();

      expect(loaded.masterEnabled, isFalse);
      expect(loaded.reminders, hasLength(4));
      expect(loaded.byId(MealReminderDefaults.lunchId)?.enabled, isFalse);
      expect(loaded.byId(MealReminderDefaults.lunchId)?.hour, 12);
      expect(loaded.byId('custom_snack')?.title, 'Lanche');
      expect(loaded.byId('custom_snack')?.minute, 30);
    });

    test('migra preferências legadas v1', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'meal_reminders_master_enabled': true,
        'meal_reminders_breakfast_enabled': true,
        'meal_reminders_breakfast_hour': 8,
        'meal_reminders_breakfast_minute': 0,
        'meal_reminders_lunch_enabled': false,
        'meal_reminders_lunch_hour': 13,
        'meal_reminders_lunch_minute': 15,
        'meal_reminders_dinner_enabled': true,
        'meal_reminders_dinner_hour': 20,
        'meal_reminders_dinner_minute': 10,
      });

      final loaded = await MealReminderPrefs.load();
      expect(loaded.reminders, hasLength(3));
      expect(loaded.byId(MealReminderDefaults.breakfastId)?.hour, 8);
      expect(loaded.byId(MealReminderDefaults.lunchId)?.enabled, isFalse);
      expect(loaded.byId(MealReminderDefaults.dinnerId)?.minute, 10);
    });
  });

  group('nextInstanceOfTime', () {
    setUpAll(() {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    });

    test('usa o horário de hoje quando ainda não passou', () {
      final now = DateTime(2026, 7, 24, 7, 0);
      final next = nextInstanceOfTime(hour: 7, minute: 45, now: now);

      expect(next.year, 2026);
      expect(next.month, 7);
      expect(next.day, 24);
      expect(next.hour, 7);
      expect(next.minute, 45);
    });

    test('adianta para amanhã quando o horário já passou', () {
      final now = DateTime(2026, 7, 24, 12, 0);
      final next = nextInstanceOfTime(hour: 11, minute: 45, now: now);

      expect(next.day, 25);
      expect(next.hour, 11);
      expect(next.minute, 45);
    });
  });
}
