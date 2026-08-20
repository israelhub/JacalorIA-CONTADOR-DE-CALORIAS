import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_anchored_menu.dart';
import '../../../shared/widgets/framed_avatar.dart';
import '../helpers/social_group_helpers.dart';
import '../models/jaca_emoji_catalog.dart';
import '../models/social_group_chat_message.dart';
import 'social_group_chat_message_actions.dart';

class SocialGroupChatBubble extends StatelessWidget {
  const SocialGroupChatBubble({
    super.key,
    required this.message,
    this.onAction,
    this.onAvatarTap,
    this.onReact,
    this.ownedStickerIds = const <String>{},
    this.showAvatar = true,
    this.showSenderName = true,
    this.isLastInGroup = true,
  });

  final SocialGroupChatMessage message;
  final ValueChanged<SocialGroupChatMessageAction>? onAction;
  final VoidCallback? onAvatarTap;
  final ValueChanged<String>? onReact;
  final Set<String> ownedStickerIds;
  final bool showAvatar;
  final bool showSenderName;
  final bool isLastInGroup;

  static const double _maxWidthFactor = 0.82;
  static const double _avatarSize = 48;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isCurrentUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: isMine
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(child: _buildBubbleColumn(isMine: true)),
              ],
            )
          : Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: _avatarSize + AppSpacing.sm,
                  ),
                  child: _buildBubbleColumn(isMine: false),
                ),
                if (showAvatar)
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: FramedAvatar(
                      key: ValueKey('group-chat-avatar-${message.id}'),
                      size: _avatarSize,
                      avatarUrl: message.senderAvatarUrl,
                      frameId: message.senderAvatarFrameId,
                      fallbackText: message.senderName,
                      backgroundColor: AppColors.homeProgressTrack,
                      onTap: onAvatarTap,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildBubbleColumn({required bool isMine}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxBubbleWidth = constraints.maxWidth * _maxWidthFactor;
        return Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMine && showSenderName)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Text(
                  message.senderName,
                  style: AppTextStyles.captionStrong.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            _buildTappableBody(
              context,
              isMine: isMine,
              maxBubbleWidth: maxBubbleWidth,
            ),
            if (message.canReact && message.reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  alignment: isMine ? WrapAlignment.end : WrapAlignment.start,
                  children: [
                    for (final reaction in message.reactions)
                      _ReactionChip(
                        reaction: reaction,
                        onTap: onReact == null
                            ? null
                            : () => onReact!(reaction.emojiId),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTappableBody(
    BuildContext context, {
    required bool isMine,
    required double maxBubbleWidth,
  }) {
    final body = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxBubbleWidth),
      child: _buildBody(context, isMine),
    );

    if (message.isDeleted || onAction == null) {
      return KeyedSubtree(
        key: ValueKey('group-chat-message-${message.id}'),
        child: body,
      );
    }

    return AppAnchoredMenu(
      targetAnchor: isMine ? Alignment.bottomRight : Alignment.bottomLeft,
      followerAnchor: isMine ? Alignment.topRight : Alignment.topLeft,
      scaleAlignment: isMine ? Alignment.topRight : Alignment.topLeft,
      childBuilder: (context, {required isOpen, required toggle}) {
        return GestureDetector(
          key: ValueKey('group-chat-message-${message.id}'),
          onTap: toggle,
          behavior: HitTestBehavior.opaque,
          child: body,
        );
      },
      menuBuilder: (context, {required close}) {
        return SocialGroupChatMessageMenu(
          message: message,
          ownedStickerIds: ownedStickerIds,
          onReact: onReact == null
              ? null
              : (emojiId) async {
                  await close();
                  onReact!(emojiId);
                },
          onSelected: (action) async {
            await close();
            onAction?.call(action);
          },
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, bool isMine) {
    if (message.isDeleted) {
      return _textBubble('Mensagem apagada', isMine, italic: true);
    }

    if (message.isEmoji) {
      final emoji = JacaEmojiCatalog.byId(message.body);
      if (emoji == null) {
        return _textBubble(message.body ?? '', isMine);
      }
      return Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.replyTo != null) ...[
            SocialChatQuoteFrame(
              backgroundColor: isMine
                  ? const Color(0x14000000)
                  : AppColors.homeProgressTrack,
              child: _ReplyQuoteBody(reply: message.replyTo!),
            ),
            const SizedBox(height: 6),
          ],
          Image.asset(
            emoji.assetPath,
            width: 112,
            height: 112,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Text(
              emoji.label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.brand900Variant,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 4),
          _ChatTimestamp(
            key: ValueKey('group-chat-timestamp-${message.id}'),
            createdAt: message.createdAt,
            isEdited: message.isEdited,
            color: AppColors.textTertiary,
          ),
        ],
      );
    }

    if (message.isImage) {
      final url = message.imageUrl?.trim() ?? '';
      if (url.isEmpty) {
        return _textBubble('Imagem indisponível', isMine);
      }
      return _imageBubble(url, isMine);
    }

    return _textBubble(message.body ?? '', isMine);
  }

  Widget _textBubble(String text, bool isMine, {bool italic = false}) {
    final bodyStyle = AppTextStyles.bodyMedium.copyWith(
      color: AppColors.brand900Variant,
      fontSize: 15,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    );
    final timeStyle = AppTextStyles.captionStrong.copyWith(
      color: AppColors.textTertiary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );
    final timeLabel = socialChatTimestampLabel(
      createdAt: message.createdAt,
      isEdited: !italic && message.isEdited,
    );

    return IntrinsicWidth(
      child: Container(
        constraints: const BoxConstraints(minWidth: 80),
        padding: const EdgeInsets.fromLTRB(12, 9, 10, 7),
        decoration: _bubbleDecoration(isMine),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.replyTo != null && !italic) ...[
              SocialChatQuoteFrame(
                backgroundColor: isMine
                    ? const Color(0x14000000)
                    : AppColors.homeProgressTrack,
                child: _ReplyQuoteBody(reply: message.replyTo!),
              ),
              const SizedBox(height: 6),
            ],
            Stack(
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: text, style: bodyStyle),
                      TextSpan(
                        text: '  $timeLabel',
                        style: timeStyle.copyWith(color: Colors.transparent),
                      ),
                    ],
                  ),
                  softWrap: true,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Text(
                    timeLabel,
                    key: ValueKey('group-chat-timestamp-${message.id}'),
                    style: timeStyle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageBubble(String url, bool isMine) {
    final photo = Stack(
      alignment: Alignment.bottomRight,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(
            message.replyTo == null ? AppRadius.md : AppRadius.sm,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 248, maxHeight: 312),
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, __) => const SizedBox(
                width: 176,
                height: 132,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.action500,
                  ),
                ),
              ),
              errorWidget: (_, __, ___) =>
                  _textBubble('Não foi possível carregar a imagem', isMine),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 6),
          child: _ChatTimestamp(
            createdAt: message.createdAt,
            isEdited: message.isEdited,
            color: Colors.white,
            shadows: const [Shadow(color: Color(0x99000000), blurRadius: 4)],
          ),
        ),
      ],
    );

    if (message.replyTo == null) return photo;

    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: _bubbleDecoration(isMine),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SocialChatQuoteFrame(
              backgroundColor: isMine
                  ? const Color(0x14000000)
                  : AppColors.homeProgressTrack,
              child: _ReplyQuoteBody(reply: message.replyTo!),
            ),
            const SizedBox(height: 6),
            photo,
          ],
        ),
      ),
    );
  }

  BoxDecoration _bubbleDecoration(bool isMine) {
    final tail = isLastInGroup;
    return BoxDecoration(
      color: isMine ? AppColors.missionsXpPill : AppColors.surfaceAlt,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(18),
        topRight: const Radius.circular(18),
        bottomLeft: Radius.circular(isMine || !tail ? 18 : 5),
        bottomRight: Radius.circular(!isMine || !tail ? 18 : 5),
      ),
      border: Border.all(color: AppColors.performanceCardBorder),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({required this.reaction, this.onTap});

  final SocialGroupChatReaction reaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final emoji = JacaEmojiCatalog.byId(reaction.emojiId);
    if (emoji == null) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('group-chat-reaction-${reaction.emojiId}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
          decoration: BoxDecoration(
            color: reaction.reactedByMe
                ? AppColors.missionsXpPill
                : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: reaction.reactedByMe
                  ? AppColors.action500
                  : AppColors.performanceCardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                emoji.assetPath,
                width: 18,
                height: 18,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.emoji_emotions_outlined,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${reaction.count}',
                style: AppTextStyles.captionStrong.copyWith(
                  color: AppColors.brand900Variant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SocialChatQuoteFrame extends StatelessWidget {
  const SocialChatQuoteFrame({
    super.key,
    required this.child,
    required this.backgroundColor,
    this.trailing,
  });

  final Widget child;
  final Color backgroundColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: ColoredBox(
        color: backgroundColor,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ColoredBox(
                color: AppColors.action500,
                child: SizedBox(width: 3),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
                  child: child,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _ReplyQuoteBody extends StatelessWidget {
  const _ReplyQuoteBody({required this.reply});

  final SocialGroupChatReplyTo reply;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          reply.senderName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.captionStrong.copyWith(
            color: AppColors.brand900,
          ),
        ),
        Text(
          reply.preview,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.captionStrong.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ChatTimestamp extends StatelessWidget {
  const _ChatTimestamp({
    super.key,
    required this.createdAt,
    required this.isEdited,
    required this.color,
    this.shadows,
  });

  final DateTime createdAt;
  final bool isEdited;
  final Color color;
  final List<Shadow>? shadows;

  @override
  Widget build(BuildContext context) {
    return Text(
      socialChatTimestampLabel(createdAt: createdAt, isEdited: isEdited),
      style: AppTextStyles.captionStrong.copyWith(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        shadows: shadows,
      ),
    );
  }
}

Future<void> openSocialGroupChatImage(BuildContext context, String url) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: Stack(
          children: [
            InteractiveViewer(
              child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    },
  );
}
