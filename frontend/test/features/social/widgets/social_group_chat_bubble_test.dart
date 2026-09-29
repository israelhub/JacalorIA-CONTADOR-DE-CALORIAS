import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jacaloria/features/social/models/social_group_chat_message.dart';
import 'package:jacaloria/features/social/widgets/social_group_chat_bubble.dart';

SocialGroupChatMessage _textMessage({
  required String id,
  required String body,
  bool isMine = false,
  String type = 'text',
}) {
  return SocialGroupChatMessage(
    id: id,
    groupId: 'group-1',
    userId: isMine ? 'me' : 'other',
    type: type,
    body: body,
    imageUrl: null,
    createdAt: DateTime(2026, 8, 19, 12, 4),
    senderName: isMine ? 'Eu' : 'Ana',
    senderAvatarUrl: null,
    senderAvatarFrameId: null,
    isCurrentUser: isMine,
  );
}

Future<void> _pumpBubble(
  WidgetTester tester, {
  required SocialGroupChatMessage message,
  VoidCallback? onAvatarTap,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 400,
            child: SocialGroupChatBubble(
              message: message,
              onAvatarTap: onAvatarTap,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('balao curto acompanha o texto', (tester) async {
    await _pumpBubble(
      tester,
      message: _textMessage(id: 'm1', body: 'Oi'),
    );
    await tester.pump();

    final size = tester.getSize(
      find.byKey(const ValueKey('group-chat-message-m1')),
    );
    expect(size.width, lessThan(180));

    final textRect = tester.getRect(find.textContaining('Oi'));
    final timeRect = tester.getRect(
      find.byKey(const ValueKey('group-chat-timestamp-m1')),
    );
    expect(timeRect.bottom, closeTo(textRect.bottom, 2));
    expect(timeRect.top, greaterThanOrEqualTo(textRect.top - 1));
  });

  testWidgets('texto longo quebra antes da largura total', (tester) async {
    final body = List.filled(24, 'mensagem').join(' ');
    await _pumpBubble(
      tester,
      message: _textMessage(id: 'm2', body: body, isMine: true),
    );
    await tester.pump();

    final size = tester.getSize(
      find.byKey(const ValueKey('group-chat-message-m2')),
    );
    expect(size.width, lessThan(340));
    expect(size.height, greaterThan(48));
    expect(find.textContaining(body), findsOneWidget);
  });

  testWidgets('toca no avatar e abre o perfil do remetente', (tester) async {
    var taps = 0;
    await _pumpBubble(
      tester,
      message: _textMessage(id: 'm3', body: 'Oi'),
      onAvatarTap: () => taps += 1,
    );
    await tester.pump();

    final avatar = tester.getSize(
      find.byKey(const ValueKey('group-chat-avatar-m3')),
    );
    expect(avatar.width, 48);
    expect(avatar.height, 48);

    await tester.tap(find.byKey(const ValueKey('group-chat-avatar-m3')));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(find.byKey(const ValueKey('group-chat-action-reply')), findsNothing);
  });

  testWidgets('mostra chip da reação abaixo do balão', (tester) async {
    await _pumpBubble(
      tester,
      message: _textMessage(id: 'm4', body: 'Oi').copyWith(
        reactions: const [
          SocialGroupChatReaction(
            emojiId: 'feliz',
            count: 2,
            reactedByMe: true,
          ),
        ],
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('group-chat-reaction-feliz')),
      findsOneWidget,
    );
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('mensagem agrupada reserva o espaco sem repetir o avatar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: SocialGroupChatBubble(
              message: _textMessage(id: 'm5', body: 'Primeira'),
              showAvatar: false,
              showSenderName: true,
              isLastInGroup: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('group-chat-avatar-m5')), findsNothing);
    expect(find.text('Ana'), findsOneWidget);
  });

  testWidgets('espaco entre baloes agrupados permanece igual ate a ultima', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SocialGroupChatBubble(
                message: _textMessage(id: 'm1', body: 'Um'),
                showAvatar: false,
                showSenderName: true,
                isLastInGroup: false,
              ),
              SocialGroupChatBubble(
                message: _textMessage(id: 'm2', body: 'Dois'),
                showAvatar: false,
                showSenderName: false,
                isLastInGroup: false,
              ),
              SocialGroupChatBubble(
                message: _textMessage(id: 'm3', body: 'Tres'),
                showAvatar: true,
                showSenderName: false,
                isLastInGroup: true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final first = tester.getRect(
      find.byKey(const ValueKey('group-chat-message-m1')),
    );
    final second = tester.getRect(
      find.byKey(const ValueKey('group-chat-message-m2')),
    );
    final third = tester.getRect(
      find.byKey(const ValueKey('group-chat-message-m3')),
    );

    expect(second.top - first.bottom, closeTo(third.top - second.bottom, 1));
  });

  testWidgets('horario do sticker fica abaixo da figurinha', (tester) async {
    await _pumpBubble(
      tester,
      message: _textMessage(id: 'm6', body: 'feliz', type: 'emoji'),
    );
    await tester.pump();

    final timeRect = tester.getRect(
      find.byKey(const ValueKey('group-chat-timestamp-m6')),
    );
    final sticker = tester.getRect(find.byType(Image));
    expect(timeRect.top, greaterThan(sticker.bottom));
  });
}
