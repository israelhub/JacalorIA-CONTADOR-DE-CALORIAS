import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../helpers/food_review_helpers.dart';
import 'food_meal_type_chips.dart';

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
    final hasNetworkImage = (widget.imageUrl ?? '')
        .trim()
        .toLowerCase()
        .startsWith('http');
    final hasAssetImage = (widget.imageAsset ?? '').trim().startsWith(
      'assets/',
    );
    final hasImage = hasBytes || hasNetworkImage || hasAssetImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasImage) ...[
          Container(
            key: const ValueKey('food-review-image-container'),
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasBytes
                ? Image.memory(
                    widget.imageBytes!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => const SizedBox.expand(),
                  )
                : hasNetworkImage
                ? AppNetworkImage(
                    url: widget.imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: AppRadius.md,
                    error: const SizedBox.expand(),
                  )
                : Image.asset(
                    widget.imageAsset!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Container(
          key: const ValueKey('food-review-meal-type-card'),
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                            cursorColor: AppColors.brand900,
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
              FoodMealTypeChips(
                selected: widget.mealType,
                onSelected: (type) {
                  if (type != null) {
                    widget.onMealTypeChanged(type);
                  }
                },
                keyPrefix: 'food-review-meal-type',
                expand: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
