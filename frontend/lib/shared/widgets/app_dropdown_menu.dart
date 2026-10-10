import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_input.dart';

class AppDropdownMenu extends StatefulWidget {
  const AppDropdownMenu({
    super.key,
    required this.selectedValue,
    required this.options,
    required this.onSelected,
    this.label,
    this.hint,
    this.fieldKey,
    this.enabled = true,
  });

  final String selectedValue;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final String? label;
  final String? hint;
  final Key? fieldKey;
  final bool enabled;

  @override
  State<AppDropdownMenu> createState() => _AppDropdownMenuState();
}

class _AppDropdownMenuState extends State<AppDropdownMenu> {
  final GlobalKey _anchorKey = GlobalKey();

  Future<void> _openMenu() async {
    if (!widget.enabled) {
      return;
    }

    final fieldContext = _anchorKey.currentContext;
    if (fieldContext == null) {
      return;
    }

    final fieldBox = fieldContext.findRenderObject() as RenderBox?;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;

    if (fieldBox == null || overlayBox == null) {
      return;
    }

    final fieldOffset = fieldBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
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
        side: const BorderSide(color: AppColors.inputBorder),
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
                  padding: AppInputStyles.singleLineContentPadding,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      option,
                      style: AppInputStyles.value.copyWith(
                        color: option == widget.selectedValue
                            ? AppColors.action500
                            : AppColors.textPrimary,
                        fontWeight: option == widget.selectedValue
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );

    if (selectedValue != null) {
      widget.onSelected(selectedValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label?.trim() ?? '';
    final hasLabel = label.isNotEmpty;
    final hasValue = widget.selectedValue.trim().isNotEmpty;

    final field = Material(
      color: Colors.transparent,
      child: InkWell(
        key: widget.fieldKey,
        onTap: widget.enabled ? _openMenu : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InputDecorator(
          key: _anchorKey,
          isEmpty: !hasValue,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppInputStyles.hint,
            filled: true,
            fillColor: AppColors.surface,
            isDense: true,
            enabled: widget.enabled,
            contentPadding: AppInputStyles.singleLineContentPadding,
            suffixIcon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: widget.enabled
                  ? AppColors.textSecondary
                  : AppColors.textTertiary,
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
          ),
          child: Text(
            hasValue ? widget.selectedValue : '',
            style: AppInputStyles.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );

    if (!hasLabel) {
      return field;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        field,
      ],
    );
  }
}
