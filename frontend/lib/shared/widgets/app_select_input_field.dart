import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppSelectInputField extends StatefulWidget {
  const AppSelectInputField({
    super.key,
    required this.selectedValue,
    required this.options,
    required this.onSelected,
    this.label,
    this.hint,
    this.fieldKey,
    this.compact = false,
  });

  final String selectedValue;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final String? label;
  final String? hint;
  final Key? fieldKey;
  final bool compact;

  @override
  State<AppSelectInputField> createState() => _AppSelectInputFieldState();
}

class _AppSelectInputFieldState extends State<AppSelectInputField> {
  final GlobalKey _anchorKey = GlobalKey();

  Future<void> _openMenu() async {
    final fieldContext = _anchorKey.currentContext;
    if (fieldContext == null) {
      return;
    }

    final fieldBox = fieldContext.findRenderObject() as RenderBox?;
    final overlayBox = Overlay.of(context).context.findRenderObject() as RenderBox?;

    if (fieldBox == null || overlayBox == null) {
      return;
    }

    final fieldOffset = fieldBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final fieldRect = Rect.fromLTWH(
      fieldOffset.dx,
      fieldOffset.dy,
      fieldBox.size.width,
      fieldBox.size.height,
    );

    final selectedValue = await showMenu<String>(
      context: context,
      color: AppColors.surface,
      elevation: 2,
      constraints: BoxConstraints.tightFor(width: fieldRect.width),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      position: RelativeRect.fromLTRB(
        fieldRect.left,
        fieldRect.bottom + AppSpacing.xs,
        overlayBox.size.width - fieldRect.right,
        overlayBox.size.height - fieldRect.bottom,
      ),
      items: widget.options
          .map(
            (option) => PopupMenuItem<String>(
              value: option,
              height: AppSpacing.huge + AppSpacing.lg,
              padding: EdgeInsets.zero,
              child: SizedBox(
                width: fieldRect.width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      option,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );

    if (selectedValue != null) {
      widget.onSelected(selectedValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveKey = widget.fieldKey;
    final label = widget.label?.trim() ?? '';
    final hasLabel = label.isNotEmpty && !widget.compact;
    final value = widget.selectedValue.trim().isNotEmpty
        ? widget.selectedValue
        : (widget.hint ?? '');
    final valueColor = widget.selectedValue.trim().isNotEmpty
        ? AppColors.textPrimary
        : AppColors.textSecondary;

    final interactive = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openMenu,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.inputBorder),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowButtonAlt,
                offset: Offset(0, 4),
                blurRadius: 0,
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? AppSpacing.md : AppSpacing.lg,
            vertical: widget.compact ? AppSpacing.xs : AppSpacing.md,
          ),
          child: Row(
            mainAxisSize: widget.compact ? MainAxisSize.min : MainAxisSize.max,
            children: [
              if (!widget.compact) Expanded(
                child: Text(
                  value,
                  style: AppTextStyles.bodyLarge.copyWith(color: valueColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ) else ...[
                Text(
                  value,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (!widget.compact) ...[
                const SizedBox(width: AppSpacing.sm),
              ],
              const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );

    final field = effectiveKey == null
        ? KeyedSubtree(key: _anchorKey, child: interactive)
        : KeyedSubtree(
            key: effectiveKey,
            child: KeyedSubtree(key: _anchorKey, child: interactive),
          );

    if (widget.compact) {
      return field;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasLabel) ...[
          Text(
            label,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        field,
      ],
    );
  }
}