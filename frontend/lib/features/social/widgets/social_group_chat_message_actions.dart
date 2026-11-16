import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../models/jaca_emoji_catalog.dart';
import '../models/social_group_chat_message.dart';

enum SocialGroupChatMessageAction { reply, edit, delete, view }

class SocialGroupChatMessageMenu extends StatelessWidget {
  const SocialGroupChatMessageMenu({
    super.key,
    required this.message,
    required this.onSelected,
    this.ownedStickerIds = const <String>{},
    this.onReact,
  });

  final SocialGroupChatMessage message;
  final ValueChanged<SocialGroupChatMessageAction> onSelected;
  final Set<String> ownedStickerIds;
  final ValueChanged<String>? onReact;

  @override
  Widget build(BuildContext context) {
    final stickers = JacaEmojiCatalog.visibleItems(ownedStickerIds);
    final items =
        <
          ({
            Key key,
            IconData icon,
            String label,
            Color? color,
            SocialGroupChatMessageAction action,
          })
        >[
          (
            key: const ValueKey('group-chat-action-reply'),
            icon: Icons.reply_rounded,
            label: 'Responder',
            color: null,
            action: SocialGroupChatMessageAction.reply,
          ),
          if (message.canEdit)
            (
              key: const ValueKey('group-chat-action-edit'),
              icon: Icons.edit_rounded,
              label: 'Editar',
              color: null,
              action: SocialGroupChatMessageAction.edit,
            ),
          if (message.isImage)
            (
              key: const ValueKey('group-chat-action-view'),
              icon: Icons.fullscreen_rounded,
              label: 'Ver foto',
              color: null,
              action: SocialGroupChatMessageAction.view,
            ),
          if (message.canDelete)
            (
              key: const ValueKey('group-chat-action-delete'),
              icon: Icons.delete_outline_rounded,
              label: 'Excluir',
              color: AppColors.textError,
              action: SocialGroupChatMessageAction.delete,
            ),
        ];

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 248,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.performanceCardBorder, width: 2),
          boxShadow: AppShadows.performanceCard,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md - 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onReact != null && stickers.isNotEmpty) ...[
                _ReactionStickerRow(
                  stickers: stickers,
                  selectedId: message.myReactionEmojiId,
                  onReact: onReact!,
                ),
                if (items.isNotEmpty)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.performanceTrack,
                  ),
              ],
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.performanceTrack,
                  ),
                _MenuItem(
                  key: items[i].key,
                  icon: items[i].icon,
                  label: items[i].label,
                  color: items[i].color,
                  onTap: () => onSelected(items[i].action),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReactionStickerRow extends StatelessWidget {
  const _ReactionStickerRow({
    required this.stickers,
    required this.selectedId,
    required this.onReact,
  });

  final List<JacaEmojiItem> stickers;
  final String? selectedId;
  final ValueChanged<String> onReact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        itemCount: stickers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          final emoji = stickers[index];
          final selected = selectedId == emoji.id;
          return InkWell(
            key: ValueKey('group-chat-react-${emoji.id}'),
            onTap: () => onReact(emoji.id),
            borderRadius: BorderRadius.circular(10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.missionsXpPill
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: selected
                    ? Border.all(color: AppColors.action500)
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Image.asset(
                  emoji.assetPath,
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.emoji_emotions_outlined,
                    size: 22,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? AppColors.brand900Variant;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, color: foreground, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
