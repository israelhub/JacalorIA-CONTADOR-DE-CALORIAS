import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../helpers/food_review_helpers.dart';

class FoodReviewMealHeader extends StatefulWidget {
  const FoodReviewMealHeader({
    super.key,
    required this.imageBytes,
    this.imageAsset,
    this.imageUrl,
    required this.titleController,
    required this.timeLabel,
    required this.mealType,
    required this.onMealTypeChanged,
    this.onTitleChanged,
  });

  final Uint8List? imageBytes;
  final String? imageAsset;
  final String? imageUrl;
  final TextEditingController titleController;
  final String timeLabel;
  final FoodMealType mealType;
  final ValueChanged<FoodMealType> onMealTypeChanged;
  final ValueChanged<String>? onTitleChanged;

  @override
  State<FoodReviewMealHeader> createState() => _FoodReviewMealHeaderState();
}

class _FoodReviewMealHeaderState extends State<FoodReviewMealHeader> {
  late final FocusNode _titleFocusNode;
  bool _isEditingTitle = false;

  @override
  void initState() {
    super.initState();
    _titleFocusNode = FocusNode();
    _titleFocusNode.addListener(_handleTitleFocusChange);
  }

  @override
  void dispose() {
    _titleFocusNode
      ..removeListener(_handleTitleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleTitleFocusChange() {
    if (!_titleFocusNode.hasFocus && _isEditingTitle && mounted) {
      setState(() {
        _isEditingTitle = false;
      });
    }
  }

  void _startEditingTitle() {
    setState(() {
      _isEditingTitle = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _titleFocusNode.requestFocus();
      widget.titleController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.titleController.text.length,
      );
    });
  }

  void _finishEditingTitle() {
    _titleFocusNode.unfocus();
    if (mounted) {
      setState(() {
        _isEditingTitle = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBytes = widget.imageBytes != null && widget.imageBytes!.isNotEmpty;
    final hasNetworkImage =
        (widget.imageUrl ?? '').trim().toLowerCase().startsWith('http');
    final hasAssetImage = (widget.imageAsset ?? '').trim().startsWith('assets/');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: const ValueKey('food-review-image-container'),
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.foodReviewFieldBorder),
            boxShadow: AppShadows.foodReviewField,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: hasBytes
                ? Image.memory(
                    widget.imageBytes!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  )
                : hasNetworkImage
                ? Image(
                    image: CachedNetworkImageProvider(widget.imageUrl!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    gaplessPlayback: true,
                    frameBuilder: (_, child, frame, wasSyncLoaded) {
                      if (wasSyncLoaded || frame != null) {
                        return child;
                      }
                      return const AppSkeletonBox(
                        height: double.infinity,
                        borderRadius: 0,
                      );
                    },
                    errorBuilder: (_, __, ___) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.textSecondary,
                            size: 42,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Imagem não cadastrada',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  )
                : hasAssetImage
                ? Image.asset(
                    widget.imageAsset!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.textSecondary,
                          size: 42,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Imagem não cadastrada',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _isEditingTitle
                  ? TextField(
                      key: const ValueKey('food-review-meal-title-field'),
                      controller: widget.titleController,
                      focusNode: _titleFocusNode,
                      onChanged: widget.onTitleChanged,
                      textAlignVertical: const TextAlignVertical(y: -0.2),
                      style: AppTextStyles.headingMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        height: 28 / 24,
                        letterSpacing: -0.12,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _finishEditingTitle(),
                    )
                  : InkWell(
                      key: const ValueKey('food-review-meal-title-text'),
                      onTap: _startEditingTitle,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: Text(
                          widget.titleController.text.trim().isEmpty
                              ? 'Refeição'
                              : widget.titleController.text.trim(),
                          style: AppTextStyles.headingMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            height: 28 / 24,
                            letterSpacing: -0.12,
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              widget.timeLabel,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 22 / 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Tipo de refeição',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: FoodMealType.values.map((type) {
            final isSelected = widget.mealType == type;
            return ChoiceChip(
              key: ValueKey('food-review-meal-type-${type.apiValue}'),
              selected: isSelected,
              showCheckmark: false,
              label: Text(type.chipLabel),
              backgroundColor: AppColors.surfaceAlt,
              selectedColor: AppColors.action500.withValues(alpha: 0.2),
              side: BorderSide(
                color: isSelected ? AppColors.action500 : AppColors.borderAlt,
              ),
              labelStyle: AppTextStyles.bodyMedium.copyWith(
                color: isSelected
                    ? AppColors.action500
                    : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              onSelected: (_) => widget.onMealTypeChanged(type),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }
}
