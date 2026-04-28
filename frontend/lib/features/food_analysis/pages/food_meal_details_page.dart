import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../shared/helpers/profile_value_helpers.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/macro_progress_indicator.dart';
import '../helpers/food_review_helpers.dart';
import '../models/food_meal_record.dart';
import '../widgets/food_analysis_page_header.dart';
import '../widgets/food_meal_item_row.dart';

class FoodMealDetailsPage extends StatefulWidget {
  const FoodMealDetailsPage({
    super.key,
    required this.record,
    this.userProfile,
  });

  final FoodMealRecord record;
  final Map<String, dynamic>? userProfile;

  @override
  State<FoodMealDetailsPage> createState() => _FoodMealDetailsPageState();
}

class _FoodMealDetailsPageState extends State<FoodMealDetailsPage> {
  late final List<bool> _sectionVisible;
  bool _started = false;

  static const Duration _sectionRevealDuration = Duration(milliseconds: 280);

  @override
  void initState() {
    super.initState();
    _sectionVisible = List<bool>.filled(4, false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_started) {
        _started = true;
        _revealSections();
      }
    });
  }

  void _revealSections() {
    if (!mounted) {
      return;
    }

    setState(() {
      for (var index = 0; index < _sectionVisible.length; index++) {
        _sectionVisible[index] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mealTitle = foodMealTitleFromTimeLabel(widget.record.timeLabel);
    final consumedCalories = widget.record.calories;
    final goalProtein = readProfileInt(widget.userProfile, const [
      'daily_protein_goal',
      'dailyProteinGoal',
    ], fallback: 120);
    final goalCarbs = readProfileInt(widget.userProfile, const [
      'daily_carbs_goal',
      'dailyCarbsGoal',
    ], fallback: 200);
    final goalFat = readProfileInt(widget.userProfile, const [
      'daily_fat_goal',
      'dailyFatGoal',
    ], fallback: 60);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const FoodAnalysisPageHeader(title: 'Detalhes da refeição'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            _RevealSection(
              visible: _sectionVisible[0],
              duration: _sectionRevealDuration,
              child: _MealHeroImage(
                imageBytes: widget.record.imageBytes,
                imageAsset: widget.record.imageAsset,
                imageUrl: widget.record.imageUrl,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _RevealSection(
              visible: _sectionVisible[1],
              duration: _sectionRevealDuration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      mealTitle,
                      style: AppTextStyles.homeUserName.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    widget.record.timeLabel,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _RevealSection(
              visible: _sectionVisible[2],
              duration: _sectionRevealDuration,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.foodReviewFieldBorder,
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.foodReviewFieldShadow,
                      offset: Offset(0, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$consumedCalories Calorias consumidas',
                      style: AppTextStyles.homeSectionTitle.copyWith(
                        color: AppColors.brand900Variant,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: MacroProgressIndicator(
                            label: 'Carboidratos',
                            consumed: widget.record.carbs,
                            goal: goalCarbs,
                            color: AppColors.homeMacroCarbs,
                            progressKey: const ValueKey(
                              'meal-details-macro-carboidratos',
                            ),
                            labelStyle: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.brand900Variant,
                              fontWeight: FontWeight.w500,
                            ),
                            valueStyle: AppTextStyles.captionStrong.copyWith(
                              color: AppColors.brand900Variant,
                              fontWeight: FontWeight.w500,
                            ),
                            trackColor: AppColors.homeProgressTrack,
                            barHeight: 10,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: MacroProgressIndicator(
                            label: 'Proteínas',
                            consumed: widget.record.protein,
                            goal: goalProtein,
                            color: AppColors.homeMacroProtein,
                            progressKey: const ValueKey(
                              'meal-details-macro-proteinas',
                            ),
                            labelStyle: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.brand900Variant,
                              fontWeight: FontWeight.w500,
                            ),
                            valueStyle: AppTextStyles.captionStrong.copyWith(
                              color: AppColors.brand900Variant,
                              fontWeight: FontWeight.w500,
                            ),
                            trackColor: AppColors.homeProgressTrack,
                            barHeight: 10,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: MacroProgressIndicator(
                            label: 'Gorduras',
                            consumed: widget.record.fat,
                            goal: goalFat,
                            color: AppColors.homeMacroFat,
                            progressKey: const ValueKey(
                              'meal-details-macro-gorduras',
                            ),
                            labelStyle: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.brand900Variant,
                              fontWeight: FontWeight.w500,
                            ),
                            valueStyle: AppTextStyles.captionStrong.copyWith(
                              color: AppColors.brand900Variant,
                              fontWeight: FontWeight.w500,
                            ),
                            trackColor: AppColors.homeProgressTrack,
                            barHeight: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _RevealSection(
              visible: _sectionVisible[3],
              duration: _sectionRevealDuration,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.foodReviewFieldBorder,
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.foodReviewFieldShadow,
                      offset: Offset(0, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alimentos presentes na refeição',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.brand900Variant,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (widget.record.items.isEmpty)
                      Text(
                        'Nenhum alimento encontrado.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      )
                    else
                      Column(
                        children: [
                          const SizedBox(height: AppSpacing.xs),
                          ...widget.record.items.asMap().entries.expand((
                            entry,
                          ) {
                            final index = entry.key;
                            final item = entry.value;

                            return <Widget>[
                              FoodMealItemRow(item: item),
                              if (index != widget.record.items.length - 1)
                                const Divider(
                                  color: AppColors.divider,
                                  height: AppSpacing.lg,
                                  thickness: 1,
                                ),
                            ];
                          }),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevealSection extends StatelessWidget {
  const _RevealSection({
    required this.visible,
    required this.duration,
    required this.child,
  });

  final bool visible;
  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: duration,
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 0.05),
        duration: duration,
        curve: Curves.easeOutCubic,
        child: child,
      ),
    );
  }
}

class _MealHeroImage extends StatelessWidget {
  const _MealHeroImage({
    required this.imageBytes,
    required this.imageAsset,
    required this.imageUrl,
  });

  final Uint8List? imageBytes;
  final String? imageAsset;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: const [
          BoxShadow(
            color: AppColors.foodReviewFieldShadow,
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    if (imageBytes != null) {
      return Image.memory(
        imageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }

    final asset =
        imageAsset ?? 'assets/images/smiling green cartoon crocodile@2x.webp';
    return Image.asset(asset, fit: BoxFit.cover, width: double.infinity);
  }
}
