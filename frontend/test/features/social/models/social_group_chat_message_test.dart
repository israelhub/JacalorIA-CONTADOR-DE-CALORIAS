import 'package:flutter_test/flutter_test.dart';

import 'package:jacaloria/features/social/models/social_group_chat_message.dart';

void main() {
  test('parseia mensagem de texto', () {
    final message = SocialGroupChatMessage.fromJson({
      'id': 'm1',
      'groupId': 'g1',
      'userId': 'u1',
      'type': 'text',
      'body': 'Oi grupo',
      'imageUrl': null,
      'createdAt': '2026-08-19T12:00:00.000Z',
      'senderName': 'Ana',
      'senderAvatarUrl': null,
      'senderAvatarFrameId': null,
      'isCurrentUser': true,
    });

    expect(message.isText, isTrue);
    expect(message.body, 'Oi grupo');
    expect(message.isCurrentUser, isTrue);
    expect(message.canEdit, isTrue);
    expect(message.canDelete, isTrue);
    expect(message.canReply, isTrue);
  });

  test('parseia mensagem de emoji e imagem', () {
    final emoji = SocialGroupChatMessage.fromJson({
      'id': 'm2',
      'type': 'emoji',
      'body': 'feliz',
      'isCurrentUser': false,
    });
    final image = SocialGroupChatMessage.fromJson({
      'id': 'm3',
      'type': 'image',
      'imageUrl': 'https://example.com/foto.jpg',
    });

    expect(emoji.isEmoji, isTrue);
    expect(emoji.body, 'feliz');
    expect(emoji.canEdit, isFalse);
    expect(image.isImage, isTrue);
    expect(image.imageUrl, 'https://example.com/foto.jpg');
    expect(image.preview, 'Foto');
  });

  test('parseia resposta, edição e exclusão', () {
    final message = SocialGroupChatMessage.fromJson({
      'id': 'm4',
      'type': 'text',
      'body': 'Combinado',
      'editedAt': '2026-08-19T12:05:00.000Z',
      'isDeleted': false,
      'isCurrentUser': true,
      'replyTo': {
        'id': 'm1',
        'senderName': 'Ana',
        'type': 'text',
        'body': 'Vamos?',
        'isDeleted': false,
      },
    });

    expect(message.isEdited, isTrue);
    expect(message.replyTo?.senderName, 'Ana');
    expect(message.replyTo?.preview, 'Vamos?');

    final deleted = SocialGroupChatMessage.fromJson({
      'id': 'm5',
      'type': 'text',
      'isDeleted': true,
      'isCurrentUser': true,
    });
    expect(deleted.canEdit, isFalse);
    expect(deleted.canReply, isFalse);
    expect(deleted.preview, 'Mensagem apagada');
  });

  test('parseia reações da mensagem', () {
    final message = SocialGroupChatMessage.fromJson({
      'id': 'm6',
      'type': 'text',
      'body': 'Bora',
      'reactions': [
        {'emojiId': 'feliz', 'count': 2, 'reactedByMe': true},
        {'emojiId': 'fogo', 'count': 1, 'reactedByMe': false},
      ],
    });

    expect(message.reactions, hasLength(2));
    expect(message.myReactionEmojiId, 'feliz');
    expect(message.reactions.first.count, 2);
    expect(message.reactionsSignature, 'feliz:2:1|fogo:1:0');
  });
}
