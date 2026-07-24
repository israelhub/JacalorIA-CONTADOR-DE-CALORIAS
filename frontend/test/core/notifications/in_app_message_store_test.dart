import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jacaloria/core/notifications/in_app_message_models.dart';
import 'package:jacaloria/core/notifications/in_app_message_store.dart';
import 'package:jacaloria/core/notifications/meal_reminder_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InAppMessageStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    store = InAppMessageStore.instance;
    await store.resetForTest();
  });

  test('addMessage aumenta unread e markRead zera', () async {
    await store.addMessage(
      title: 'Aviso',
      body: 'Corpo',
      source: InAppMessageSources.catalog,
      id: 'm1',
    );

    expect(store.unreadCount, 1);

    await store.markRead('m1');
    expect(store.unreadCount, 0);
    expect(store.messages.single.isUnread, isFalse);
  });

  test('delete remove mensagem', () async {
    await store.addMessage(
      title: 'Aviso',
      body: 'Corpo',
      source: InAppMessageSources.catalog,
      id: 'm1',
    );
    await store.delete('m1');
    expect(store.messages, isEmpty);
    expect(store.unreadCount, 0);
  });

  test('sourceKey deduplica lembrete do mesmo dia', () async {
    final config = MealReminderConfig.defaultsForBuiltIn(
      MealReminderDefaults.lunchId,
    );
    final now = DateTime(2026, 7, 24, 13, 0);

    await store.addMealReminderMessage(config, now: now);
    await store.addMealReminderMessage(config, now: now);

    expect(store.messages.length, 1);
    expect(store.messages.single.source, InAppMessageSources.mealReminder);
  });

  test('syncDueMealReminders cria mensagens vencidas', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'meal_reminders_master_enabled': true,
      'meal_reminders_list_v2':
          '[{"id":"breakfast","title":"Café da manhã","enabled":true,"hour":7,"minute":0},'
          '{"id":"lunch","title":"Almoço","enabled":true,"hour":12,"minute":0},'
          '{"id":"dinner","title":"Jantar","enabled":false,"hour":19,"minute":0}]',
    });
    await store.resetForTest();

    await store.syncDueMealReminders(now: DateTime(2026, 7, 24, 12, 30));

    expect(store.messages.length, 2);
    expect(
      store.messages.map((item) => item.sourceKey).toSet(),
      containsAll(<String>{
        'meal_reminder:breakfast:2026-07-24',
        'meal_reminder:lunch:2026-07-24',
      }),
    );
  });
}
