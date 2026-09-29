import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jacaloria/features/social/models/social_friend_profile.dart';
import 'package:jacaloria/features/social/models/social_group_chat_message.dart';
import 'package:jacaloria/features/social/models/social_member_daily_meals.dart';
import 'package:jacaloria/features/social/pages/social_friend_profile_page.dart';
import 'package:jacaloria/features/social/pages/social_group_chat_page.dart';
import 'package:jacaloria/features/social/services/social_service.dart';

class _FakeChatService extends SocialService {
  _FakeChatService(this.messages);

  List<SocialGroupChatMessage> messages;
  int fetchCount = 0;

  @override
  Future<List<SocialGroupChatMessage>> fetchGroupMessages(
    String groupId, {
    String? after,
    String? before,
    int limit = 80,
  }) async {
    fetchCount += 1;
    if (after != null && after.isNotEmpty) {
      final index = messages.indexWhere((message) => message.id == after);
      if (index < 0) return const [];
      return messages.sublist(index + 1);
    }
    return List<SocialGroupChatMessage>.from(messages);
  }

  @override
  Future<SocialGroupChatMessage> sendGroupMessage({
    required String groupId,
    required String type,
    String? body,
    String? imageUrl,
    String? replyToId,
  }) async {
    SocialGroupChatReplyTo? replyTo;
    if (replyToId != null) {
      final index = messages.indexWhere((message) => message.id == replyToId);
      if (index >= 0) {
        final target = messages[index];
        replyTo = SocialGroupChatReplyTo(
          id: target.id,
          senderName: target.senderName,
          type: target.type,
          body: target.body,
          imageUrl: target.imageUrl,
          isDeleted: target.isDeleted,
        );
      }
    }
    final sent = SocialGroupChatMessage(
      id: 'sent-${messages.length + 1}',
      groupId: groupId,
      userId: 'me',
      type: type,
      body: body,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      senderName: 'Eu',
      senderAvatarUrl: null,
      senderAvatarFrameId: null,
      isCurrentUser: true,
      replyTo: replyTo,
    );
    messages = [...messages, sent];
    return sent;
  }

  @override
  Future<SocialFriendProfile> fetchFriendProfile(
    String friendUserId, {
    String? groupId,
    String? viaUserId,
  }) async {
    return SocialFriendProfile(
      id: friendUserId,
      name: 'Ana',
      avatarUrl: null,
      avatarFrameId: null,
      avatarBackgroundId: null,
      streakDays: 3,
      longestStreakDays: 5,
      missionsCompleted: 1,
      cosmeticsOwned: 0,
      friendCount: 2,
      totalXp: 100,
      favoriteDish: null,
      preferredPeriod: null,
      birthDate: null,
      objective: null,
      sex: null,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  @override
  Future<SocialMemberDailyMeals> fetchPublicProfileDailyMeals({
    required String userId,
    String? date,
    String? groupId,
    String? viaUserId,
  }) async {
    return const SocialMemberDailyMeals(
      enabled: false,
      competitionType: '',
      date: null,
      startsAt: null,
      endsAt: null,
      totalCalories: 0,
      meals: [],
    );
  }

  @override
  Future<SocialGroupChatMessage> editGroupMessage({
    required String groupId,
    required String messageId,
    required String body,
  }) async {
    final index = messages.indexWhere((message) => message.id == messageId);
    final current = messages[index];
    final updated = SocialGroupChatMessage(
      id: current.id,
      groupId: current.groupId,
      userId: current.userId,
      type: current.type,
      body: body,
      imageUrl: current.imageUrl,
      createdAt: current.createdAt,
      editedAt: DateTime.now(),
      senderName: current.senderName,
      senderAvatarUrl: current.senderAvatarUrl,
      senderAvatarFrameId: current.senderAvatarFrameId,
      isCurrentUser: current.isCurrentUser,
      replyTo: current.replyTo,
    );
    messages = [...messages]..[index] = updated;
    return updated;
  }

  @override
  Future<SocialGroupChatMessage> deleteGroupMessage({
    required String groupId,
    required String messageId,
  }) async {
    final index = messages.indexWhere((message) => message.id == messageId);
    final current = messages[index];
    final updated = SocialGroupChatMessage(
      id: current.id,
      groupId: current.groupId,
      userId: current.userId,
      type: current.type,
      body: null,
      imageUrl: null,
      createdAt: current.createdAt,
      isDeleted: true,
      senderName: current.senderName,
      senderAvatarUrl: current.senderAvatarUrl,
      senderAvatarFrameId: current.senderAvatarFrameId,
      isCurrentUser: current.isCurrentUser,
      replyTo: current.replyTo,
    );
    messages = [...messages]..[index] = updated;
    return updated;
  }

  @override
  Future<SocialGroupChatMessage> reactToGroupMessage({
    required String groupId,
    required String messageId,
    required String emojiId,
  }) async {
    final index = messages.indexWhere((message) => message.id == messageId);
    final current = messages[index];
    final updated = current.copyWith(
      reactions: _toggleReaction(current.reactions, emojiId),
    );
    messages = [...messages]..[index] = updated;
    return updated;
  }
}

List<SocialGroupChatReaction> _toggleReaction(
  List<SocialGroupChatReaction> current,
  String emojiId,
) {
  final alreadyThis = current.any(
    (reaction) => reaction.reactedByMe && reaction.emojiId == emojiId,
  );
  final next = <SocialGroupChatReaction>[];
  for (final reaction in current) {
    if (!reaction.reactedByMe) {
      next.add(reaction);
      continue;
    }
    if (reaction.count > 1) {
      next.add(
        SocialGroupChatReaction(
          emojiId: reaction.emojiId,
          count: reaction.count - 1,
          reactedByMe: false,
        ),
      );
    }
  }
  if (!alreadyThis) {
    final index = next.indexWhere((reaction) => reaction.emojiId == emojiId);
    if (index < 0) {
      next.add(
        SocialGroupChatReaction(
          emojiId: emojiId,
          count: 1,
          reactedByMe: true,
        ),
      );
    } else {
      final existing = next[index];
      next[index] = SocialGroupChatReaction(
        emojiId: existing.emojiId,
        count: existing.count + 1,
        reactedByMe: true,
      );
    }
  }
  return List<SocialGroupChatReaction>.unmodifiable(next);
}

SocialGroupChatMessage _message({
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

Future<void> _pumpChat(
  WidgetTester tester, {
  required _FakeChatService service,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: SocialGroupChatPage(
        groupId: 'group-1',
        groupName: 'Família Saudável',
        service: service,
      ),
    ),
  );
}

void main() {
  testWidgets('mostra estado vazio e envia texto', (tester) async {
    final service = _FakeChatService([]);
    await _pumpChat(tester, service: service);
    await tester.pump();

    expect(find.text('Família Saudável'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('group-chat-emoji-button')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.attach_file_rounded), findsOneWidget);
    expect(
      find.text('Ainda não tem mensagens.\nManda um oi para o grupo!'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'Oi pessoal');
    await tester.tap(find.byKey(const ValueKey('group-chat-send-button')));
    await tester.pump();

    expect(find.textContaining('Oi pessoal'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('group-chat-appear-sent-1')),
      findsOneWidget,
    );
    expect(service.messages, hasLength(1));
    expect(service.messages.first.type, 'text');
  });

  testWidgets('abre o painel de emojis do Jaca', (tester) async {
    final service = _FakeChatService([_message(id: 'm1', body: 'E aí')]);
    await _pumpChat(tester, service: service);
    await tester.pump();

    expect(find.textContaining('E aí'), findsOneWidget);
    expect(find.byKey(const ValueKey('jaca-emoji-feliz')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('group-chat-emoji-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('jaca-emoji-feliz')), findsOneWidget);
    expect(find.byKey(const ValueKey('jaca-emoji-festa')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('jaca-emoji-feliz')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(service.messages.last.type, 'emoji');
    expect(service.messages.last.body, 'feliz');
  });

  testWidgets('mensagem de outra pessoa so permite responder', (tester) async {
    final service = _FakeChatService([_message(id: 'm1', body: 'E aí')]);
    await _pumpChat(tester, service: service);
    await tester.pump();

    expect(find.text('12:04'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('group-chat-message-m1')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('group-chat-action-reply')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('group-chat-action-edit')), findsNothing);
    expect(
      find.byKey(const ValueKey('group-chat-action-delete')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('group-chat-action-reply')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('group-chat-reply-banner')),
      findsOneWidget,
    );
    expect(find.text('Respondendo a Ana'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Tudo bem');
    await tester.tap(find.byKey(const ValueKey('group-chat-send-button')));
    await tester.pump();

    expect(service.messages.last.body, 'Tudo bem');
    expect(service.messages.last.replyTo?.id, 'm1');
  });

  testWidgets('mensagem propria permite editar e excluir', (tester) async {
    final service = _FakeChatService([
      _message(id: 'm1', body: 'Oi pessoal', isMine: true),
    ]);
    await _pumpChat(tester, service: service);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('group-chat-message-m1')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('group-chat-action-reply')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('group-chat-action-edit')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('group-chat-action-delete')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('group-chat-action-edit')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('group-chat-edit-banner')),
      findsOneWidget,
    );
    expect(find.textContaining('Oi pessoal'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'Oi, gente');
    await tester.tap(find.byKey(const ValueKey('group-chat-send-button')));
    await tester.pump();

    expect(service.messages.single.body, 'Oi, gente');
    expect(service.messages.single.isEdited, isTrue);
    expect(find.text('editada 12:04'), findsOneWidget);
  });

  testWidgets('exclui mensagem propria', (tester) async {
    final service = _FakeChatService([
      _message(id: 'm1', body: 'Apaga essa', isMine: true),
    ]);
    await _pumpChat(tester, service: service);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('group-chat-message-m1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('group-chat-action-delete')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Excluir'));
    await tester.pump();

    expect(service.messages.single.isDeleted, isTrue);
    expect(find.textContaining('Mensagem apagada'), findsOneWidget);
  });

  testWidgets('abre o perfil ao tocar no avatar', (tester) async {
    final service = _FakeChatService([_message(id: 'm1', body: 'E aí')]);
    await _pumpChat(tester, service: service);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('group-chat-avatar-m1')));
    await tester.pumpAndSettle();

    expect(find.byType(SocialFriendProfilePage), findsOneWidget);
    expect(find.text('Ana'), findsWidgets);
  });

  testWidgets('reage a mensagem com figurinha do menu', (tester) async {
    final service = _FakeChatService([_message(id: 'm1', body: 'E aí')]);
    await _pumpChat(tester, service: service);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('group-chat-message-m1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('group-chat-react-feliz')), findsOneWidget);
    expect(find.byKey(const ValueKey('group-chat-react-festa')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('group-chat-react-feliz')));
    await tester.pumpAndSettle();

    expect(service.messages.single.myReactionEmojiId, 'feliz');
    expect(
      find.byKey(const ValueKey('group-chat-reaction-feliz')),
      findsOneWidget,
    );
  });

  testWidgets('mensagens seguidas do mesmo usuario compartilham o avatar', (
    tester,
  ) async {
    final service = _FakeChatService([
      _message(id: 'm1', body: 'Oi'),
      _message(id: 'm2', body: 'Tudo bem?'),
      _message(id: 'm3', body: 'Eu aqui', isMine: true),
    ]);
    await _pumpChat(tester, service: service);
    await tester.pump();

    expect(find.byKey(const ValueKey('group-chat-avatar-m1')), findsNothing);
    expect(find.byKey(const ValueKey('group-chat-avatar-m2')), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.textContaining('Oi'), findsOneWidget);
    expect(find.textContaining('Tudo bem?'), findsOneWidget);
  });
}
