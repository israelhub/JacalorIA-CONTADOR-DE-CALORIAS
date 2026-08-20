import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_svg_icon.dart';

class SocialGroupChatComposer extends StatelessWidget {
  const SocialGroupChatComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.isEditing,
    required this.showEmojiPicker,
    required this.onToggleEmoji,
    required this.onPickImage,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool isEditing;
  final bool showEmojiPicker;
  final VoidCallback? onToggleEmoji;
  final VoidCallback? onPickImage;
  final VoidCallback onSend;

  static const double _iconSize = 40;
  static const double _fontSize = 16;
  static const double _lineHeight = 1.25;
  static const double _fieldVPad = (_iconSize - _fontSize * _lineHeight) / 2;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular((_iconSize + 4) / 2),
          border: Border.all(color: AppColors.foodReviewFieldBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _ComposerIconButton(
                key: const ValueKey('group-chat-emoji-button'),
                iconAsset: AppIconAssets.sticker,
                semanticLabel: 'Stickers do Jaca',
                isActive: showEmojiPicker,
                onPressed: (!enabled || isEditing) ? null : onToggleEmoji,
              ),
              Expanded(
                child: _ComposerTextField(
                  controller: controller,
                  focusNode: focusNode,
                  hintText: isEditing ? 'Editar mensagem' : 'Mensagem',
                  onSubmitted: onSend,
                ),
              ),
              _ComposerIconButton(
                key: const ValueKey('group-chat-image-button'),
                icon: Icons.attach_file_rounded,
                semanticLabel: 'Enviar imagem',
                onPressed: (!enabled || isEditing) ? null : onPickImage,
              ),
              _ComposerIconButton(
                key: const ValueKey('group-chat-send-button'),
                icon: Icons.send_rounded,
                semanticLabel: 'Enviar mensagem',
                filled: true,
                onPressed: enabled ? onSend : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposerTextField extends StatelessWidget {
  const _ComposerTextField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.bodyLarge.copyWith(
      color: AppColors.textPrimary,
      fontSize: SocialGroupChatComposer._fontSize,
      fontWeight: FontWeight.w400,
      height: SocialGroupChatComposer._lineHeight,
      leadingDistribution: TextLeadingDistribution.even,
    );
    final hintStyle = style.copyWith(color: AppColors.textSecondary);
    const strut = StrutStyle(
      fontSize: SocialGroupChatComposer._fontSize,
      height: SocialGroupChatComposer._lineHeight,
      fontWeight: FontWeight.w400,
      forceStrutHeight: true,
      leading: 0,
      leadingDistribution: TextLeadingDistribution.even,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        8,
        SocialGroupChatComposer._fieldVPad,
        8,
        SocialGroupChatComposer._fieldVPad,
      ),
      child: Stack(
        alignment: Alignment.topLeft,
        children: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isNotEmpty) {
                return const SizedBox.shrink();
              }
              return IgnorePointer(
                child: Text(
                  hintText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: hintStyle,
                  strutStyle: strut,
                ),
              );
            },
          ),
          // Sempre habilitado: desabilitar durante o envio derruba o foco
          // e fecha o teclado a cada mensagem enviada.
          TextField(
            controller: controller,
            focusNode: focusNode,
            minLines: 1,
            maxLines: 4,
            style: style,
            strutStyle: strut,
            cursorColor: AppColors.brand900,
            textAlignVertical: TextAlignVertical.top,
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            scrollPadding: EdgeInsets.zero,
            decoration: const InputDecoration(
              isCollapsed: true,
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onSubmitted: (_) => onSubmitted(),
          ),
        ],
      ),
    );
  }
}

class _ComposerIconButton extends StatelessWidget {
  const _ComposerIconButton({
    super.key,
    this.icon,
    this.iconAsset,
    required this.semanticLabel,
    required this.onPressed,
    this.filled = false,
    this.isActive = false,
  });

  final IconData? icon;
  final String? iconAsset;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final bool filled;
  final bool isActive;

  static const double _size = SocialGroupChatComposer._iconSize;
  static const double _iconSize = 22;

  @override
  Widget build(BuildContext context) {
    final background = filled ? AppColors.action500 : Colors.transparent;
    final foreground = filled
        ? AppColors.surface
        : isActive
        ? AppColors.action500
        : AppColors.brand900Variant;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: _size,
          height: _size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Center(child: _buildIcon(foreground)),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(Color foreground) {
    if (iconAsset != null) {
      return AppSvgIcon(
        asset: iconAsset!,
        size: _iconSize,
        color: foreground,
        tinted: true,
      );
    }
    return Icon(icon, color: foreground, size: filled ? 20 : _iconSize);
  }
}
