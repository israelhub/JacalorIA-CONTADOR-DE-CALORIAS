import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jacaloria/core/notifications/in_app_message_store.dart';
import 'package:jacaloria/features/notifications/pages/in_app_messages_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await InAppMessageStore.instance.resetForTest();
  });

  testWidgets('marca como lida ao abrir e permite excluir', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'meal_reminders_master_enabled': false,
    });
    final store = InAppMessageStore.instance;
    await store.resetForTest();
    await store.addMessage(
      title: 'Hora do almoço',
      body: 'Registre a refeição.',
      source: 'meal_reminder',
      id: 'msg-lunch',
    );

    await tester.pumpWidget(
      MaterialApp(home: InAppMessagesPage(store: store)),
    );
    await tester.pumpAndSettle();

    expect(store.unreadCount, 1);

    await tester.tap(find.byKey(const ValueKey('in-app-message-msg-lunch')));
    await tester.pumpAndSettle();
    expect(store.unreadCount, 0);

    await tester.tap(
      find.byKey(const ValueKey('in-app-message-delete-msg-lunch')),
    );
    await tester.pumpAndSettle();

    expect(store.messages, isEmpty);
    expect(find.text('Nenhuma mensagem por enquanto.'), findsOneWidget);
  });

  testWidgets('ler tudo marca todas as mensagens como lidas', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'meal_reminders_master_enabled': false,
    });
    final store = InAppMessageStore.instance;
    await store.resetForTest();
    await store.addMessage(
      title: 'Hora do almoço',
      body: 'Registre a refeição.',
      source: 'meal_reminder',
      id: 'msg-lunch',
    );
    await store.addMessage(
      title: 'Hora do jantar',
      body: 'Não esqueça de registrar.',
      source: 'meal_reminder',
      id: 'msg-dinner',
    );

    await tester.pumpWidget(
      MaterialApp(home: InAppMessagesPage(store: store)),
    );
    await tester.pumpAndSettle();

    expect(store.unreadCount, 2);
    expect(find.text('Ler tudo'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('in-app-messages-mark-all-read')),
    );
    await tester.pumpAndSettle();

    expect(store.unreadCount, 0);
    expect(find.text('Todas as mensagens foram lidas.'), findsOneWidget);
  });
}
