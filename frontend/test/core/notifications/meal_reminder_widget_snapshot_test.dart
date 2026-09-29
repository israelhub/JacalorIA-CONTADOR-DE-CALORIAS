import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/core/notifications/meal_reminder_models.dart';
import 'package:jacaloria/core/notifications/meal_reminder_widget_snapshot.dart';

void main() {
  group('buildMealReminderWidgetSnapshot', () {
    final settings = MealReminderSettings.defaults();

    test('usa o lembrete do almoço depois do horário dele', () {
      final snapshot = buildMealReminderWidgetSnapshot(
        settings: settings,
        streakDays: 4,
        now: DateTime(2026, 8, 19, 12, 10),
      );

      expect(snapshot.streakLabel, '4 dias de sequência');
      expect(snapshot.messageTitle, contains('almoço'));
      expect(snapshot.messageBody, contains('registrar'));
      expect(snapshot.reminder?.id, MealReminderDefaults.lunchId);
    });

    test('antes do primeiro lembrete mostra o da manhã', () {
      final snapshot = buildMealReminderWidgetSnapshot(
        settings: settings,
        streakDays: 1,
        now: DateTime(2026, 8, 19, 6, 0),
      );

      expect(snapshot.streakLabel, '1 dia de sequência');
      expect(snapshot.messageTitle.toLowerCase(), contains('café'));
      expect(snapshot.reminder?.id, MealReminderDefaults.breakfastId);
    });

    test('sem lembretes ativos usa o texto padrão', () {
      final snapshot = buildMealReminderWidgetSnapshot(
        settings: const MealReminderSettings(
          masterEnabled: false,
          reminders: <MealReminderConfig>[],
        ),
        streakDays: 0,
        now: DateTime(2026, 8, 19, 15),
      );

      expect(snapshot.streakLabel, 'Comece sua sequência hoje');
      expect(snapshot.messageTitle, MealReminderWidgetSnapshot.fallbackTitle);
      expect(snapshot.messageBody, MealReminderWidgetSnapshot.fallbackBody);
      expect(snapshot.reminder, isNull);
    });
  });
}
