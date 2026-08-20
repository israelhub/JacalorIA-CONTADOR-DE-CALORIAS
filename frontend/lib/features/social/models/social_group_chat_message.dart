import 'jaca_emoji_catalog.dart';

class SocialGroupChatReplyTo {
  const SocialGroupChatReplyTo({
    required this.id,
    required this.senderName,
    required this.type,
    required this.body,
    required this.imageUrl,
    required this.isDeleted,
  });

  final String id;
  final String senderName;
  final String type;
  final String? body;
  final String? imageUrl;
  final bool isDeleted;

  String get preview {
    if (isDeleted) return 'Mensagem apagada';
    if (type == 'image') return 'Foto';
    if (type == 'emoji') {
      return JacaEmojiCatalog.byId(body)?.label ?? 'Sticker';
    }
    final text = body?.trim() ?? '';
    return text.isEmpty ? 'Mensagem' : text;
  }

  factory SocialGroupChatReplyTo.fromJson(Map<String, dynamic> json) {
    return SocialGroupChatReplyTo(
      id: json['id']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? 'Sem nome',
      type: json['type']?.toString() ?? 'text',
      body: json['body']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      isDeleted: json['isDeleted'] == true,
    );
  }
}

class SocialGroupChatReaction {
  const SocialGroupChatReaction({
    required this.emojiId,
    required this.count,
    required this.reactedByMe,
  });

  final String emojiId;
  final int count;
  final bool reactedByMe;

  factory SocialGroupChatReaction.fromJson(Map<String, dynamic> json) {
    return SocialGroupChatReaction(
      emojiId: json['emojiId']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      reactedByMe: json['reactedByMe'] == true,
    );
  }
}

class SocialGroupChatMessage {
  const SocialGroupChatMessage({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.type,
    required this.body,
    required this.imageUrl,
    required this.createdAt,
    required this.senderName,
    required this.senderAvatarUrl,
    required this.senderAvatarFrameId,
    required this.isCurrentUser,
    this.editedAt,
    this.isDeleted = false,
    this.replyTo,
    this.reactions = const [],
  });

  final String id;
  final String groupId;
  final String userId;
  final String type;
  final String? body;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool isDeleted;
  final String senderName;
  final String? senderAvatarUrl;
  final String? senderAvatarFrameId;
  final bool isCurrentUser;
  final SocialGroupChatReplyTo? replyTo;
  final List<SocialGroupChatReaction> reactions;

  bool get isText => type == 'text';
  bool get isImage => type == 'image';
  bool get isEmoji => type == 'emoji';
  bool get isEdited => editedAt != null;
  bool get canReply => !isDeleted;
  bool get canEdit => isCurrentUser && isText && !isDeleted;
  bool get canDelete => isCurrentUser && !isDeleted;
  bool get canReact => !isDeleted;

  String? get myReactionEmojiId {
    for (final reaction in reactions) {
      if (reaction.reactedByMe) return reaction.emojiId;
    }
    return null;
  }

  String get reactionsSignature => reactions
      .map(
        (reaction) =>
            '${reaction.emojiId}:${reaction.count}:${reaction.reactedByMe ? 1 : 0}',
      )
      .join('|');

  String get preview {
    return SocialGroupChatReplyTo(
      id: id,
      senderName: senderName,
      type: type,
      body: body,
      imageUrl: imageUrl,
      isDeleted: isDeleted,
    ).preview;
  }

  SocialGroupChatMessage copyWith({
    String? body,
    String? imageUrl,
    DateTime? editedAt,
    bool? isDeleted,
    SocialGroupChatReplyTo? replyTo,
    List<SocialGroupChatReaction>? reactions,
  }) {
    return SocialGroupChatMessage(
      id: id,
      groupId: groupId,
      userId: userId,
      type: type,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      senderAvatarFrameId: senderAvatarFrameId,
      isCurrentUser: isCurrentUser,
      replyTo: replyTo ?? this.replyTo,
      reactions: reactions ?? this.reactions,
    );
  }

  factory SocialGroupChatMessage.fromJson(Map<String, dynamic> json) {
    final replyJson = json['replyTo'];
    return SocialGroupChatMessage(
      id: json['id']?.toString() ?? '',
      groupId: json['groupId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      body: json['body']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      editedAt: DateTime.tryParse(json['editedAt']?.toString() ?? ''),
      isDeleted: json['isDeleted'] == true,
      senderName: json['senderName']?.toString() ?? 'Sem nome',
      senderAvatarUrl: json['senderAvatarUrl']?.toString(),
      senderAvatarFrameId: json['senderAvatarFrameId']?.toString(),
      isCurrentUser: json['isCurrentUser'] == true,
      replyTo: replyJson is Map<String, dynamic>
          ? SocialGroupChatReplyTo.fromJson(replyJson)
          : null,
      reactions: (json['reactions'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SocialGroupChatReaction.fromJson)
          .where(
            (reaction) => reaction.emojiId.isNotEmpty && reaction.count > 0,
          )
          .toList(growable: false),
    );
  }
}
