import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jacaloria/features/social/widgets/social_group_chat_composer.dart';

Future<void> _pumpComposer(
  WidgetTester tester, {
  required TextEditingController controller,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SocialGroupChatComposer(
          controller: controller,
          focusNode: FocusNode(),
          enabled: true,
          isEditing: false,
          showEmojiPicker: false,
          onToggleEmoji: () {},
          onPickImage: () {},
          onSend: () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('placeholder Mensagem alinha com o texto digitado e os icones', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await _pumpComposer(tester, controller: controller);
    await tester.pump();

    final hintFinder = find.text('Mensagem');
    final hint = tester.getRect(hintFinder);
    final send = tester.getRect(
      find.byKey(const ValueKey('group-chat-send-button')),
    );

    expect(hint.center.dy, closeTo(send.center.dy, 1.5));

    final hintTopLeft = tester.getTopLeft(hintFinder);
    await tester.enterText(find.byType(TextField), 'Olá grupo');
    await tester.pump();

    expect(find.text('Mensagem'), findsNothing);
    final typedTopLeft = tester.getTopLeft(find.text('Olá grupo'));
    expect(typedTopLeft.dx, closeTo(hintTopLeft.dx, 1));
    expect(typedTopLeft.dy, closeTo(hintTopLeft.dy, 1));
  });

  testWidgets('sticker, anexo e enviar ficam nesta ordem dentro do campo', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await _pumpComposer(tester, controller: controller);
    await tester.pump();

    final sticker = tester.getRect(
      find.byKey(const ValueKey('group-chat-emoji-button')),
    );
    final attach = tester.getRect(
      find.byKey(const ValueKey('group-chat-image-button')),
    );
    final send = tester.getRect(
      find.byKey(const ValueKey('group-chat-send-button')),
    );

    expect(sticker.left, lessThan(attach.left));
    expect(attach.left, lessThan(send.left));
    expect(attach.center.dy, closeTo(send.center.dy, 1.5));
  });
}
