import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jacaloria/features/social/widgets/social_group_chat_appear.dart';

void main() {
  testWidgets('anima mensagem nova e entrega o conteudo', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SocialGroupChatAppear(
            animate: true,
            isMine: true,
            child: Text('Oi pessoal'),
          ),
        ),
      ),
    );

    expect(find.text('Oi pessoal'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 160));
    expect(find.text('Oi pessoal'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Oi pessoal'), findsOneWidget);
  });
}
