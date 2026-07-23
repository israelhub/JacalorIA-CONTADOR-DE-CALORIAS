import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../shared/helpers/profile_value_helpers.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/macro_progress_indicator.dart';
import '../../home/services/meal_service.dart';
import '../helpers/food_review_helpers.dart';
import '../models/food_analysis_result.dart';
import '../models/food_meal_record.dart';
import '../services/food_analysis_service.dart';
import '../services/meal_template_service.dart';
import 'food_review_page.dart';
import '../widgets/food_analysis_page_header.dart';
import '../widgets/food_meal_item_row.dart';

class FoodMealDetailsPage extends StatefulWidget {
  const FoodMealDetailsPage({
    super.key,
    required this.record,
    this.userProfile,
    MealService mealService = const MealService(),
    FoodAnalysisService analysisService = const FoodAnalysisService(),
    MealTemplateService templateService = const MealTemplateService(),
  }) : _mealService = mealService,
       _analysisService = analysisService,
       _templateService = templateService;

  final FoodMealRecord record;
  final Map<String, dynamic>? userProfile;
  final MealService _mealService;
  final FoodAnalysisService _analysisService;
  final MealTemplateService _templateService;

  @override
  State<FoodMealDetailsPage> createState() => _FoodMealDetailsPageState();
}

class _FoodMealDetailsPageState extends State<FoodMealDetailsPage> {
  late final List<bool> _sectionVisible;
  late FoodMealRecord _record;
  bool _started = false;
  bool _isSavingTemplate = false;

  static const Duration _sectionRevealDuration = Duration(milliseconds: 280);

  @override
  void initState() {
    super.initState();
    _record = widget.record;
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
    final mealTitle = _record.title.trim().isEmpty
        ? foodMealTitleFromTimeLabel(_record.timeLabel)
        : _record.title.trim();
    final consumedCalories = _record.calories;
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
      appBar: FoodAnalysisPageHeader(
        title: 'Detalhes da refeição',
        actions: [
          IconButton(
            tooltip: 'Salvar para reutilizar',
            onPressed: _isSavingTemplate ? null : _handleSaveAsTemplate,
            icon: _isSavingTemplate
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bookmark_add_outlined),
          ),
          IconButton(
            tooltip: 'Editar refeição',
            onPressed: _handleEditMeal,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Excluir refeição',
            onPressed: _handleDeleteMeal,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
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
                imageBytes: _record.imageBytes,
                imageAsset: _record.imageAsset,
                imageUrl: _record.imageUrl,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _RevealSection(
              visible: _sectionVisible[1],
              duration: _sectionRevealDuration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                        _record.timeLabel,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 22 / 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.action500.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: AppColors.action500.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      _record.mealType.displayLabel,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.brand900,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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
                            consumed: _record.carbs,
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
                            label: 'Proteinas',
                            consumed: _record.protein,
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
                            consumed: _record.fat,
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
                      'Alimentos presentes na refeicao',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.brand900Variant,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (_record.items.isEmpty)
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
                          ..._record.items.asMap().entries.expand((entry) {
                            final index = entry.key;
                            final item = entry.value;

                            return <Widget>[
                              FoodMealItemRow(item: item),
                              if (index != _record.items.length - 1)
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

  Future<void> _handleSaveAsTemplate() async {
    if (_isSavingTemplate) {
      return;
    }

    setState(() => _isSavingTemplate = true);

    try {
      await widget._templateService.saveFromMeal(_record);
      if (!mounted) {
        return;
      }

      AppToast.success(
        context,
        message: 'Refeição salva. Use-a ao registrar uma nova.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      AppToast.error(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingTemplate = false);
      }
    }
  }

  Future<void> _handleEditMeal() async {
    final mealId = (_record.id ?? '').trim();
    if (mealId.isEmpty) {
      return;
    }

    final analysis = FoodAnalysisResult(
      items: _record.items,
      totals: FoodAnalysisTotals(
        calories: _record.calories.toDouble(),
        protein: _record.protein.toDouble(),
        carbs: _record.carbs.toDouble(),
        fat: _record.fat.toDouble(),
      ),
      justification: '',
    );

    final updatedMeal = await Navigator.of(context).push<FoodMealRecord>(
      MaterialPageRoute(
        builder: (_) => FoodReviewPage(
          imageBytes: _record.imageBytes,
          imageAsset: _record.imageAsset,
          imageUrl: _record.imageUrl,
          analysis: analysis,
          analysisService: widget._analysisService,
          existingMealId: mealId,
          initialMealTitle: _record.title,
          initialTimeLabel: _record.timeLabel,
          initialMealType: _record.mealType,
          recordedAt: _record.createdAt,
          showDetailsAfterSave: false,
        ),
      ),
    );

    if (!mounted || updatedMeal == null) {
      return;
    }

    setState(() {
      _record = updatedMeal;
    });
  }

  Future<void> _handleDeleteMeal() async {
    final mealId = (_record.id ?? '').trim();
    if (mealId.isEmpty) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(
            color: AppColors.foodReviewFieldBorder,
            width: 2,
          ),
        ),
        title: Text(
          'Excluir refeição',
          style: AppTextStyles.homeSectionTitle.copyWith(
            color: AppColors.brand900Variant,
          ),
        ),
        content: Text(
          'Essa refeição será excluída e você não poderá vê-la novamente.',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.brand900),
            child: Text(
              'Cancelar',
              style: AppTextStyles.label.copyWith(color: AppColors.brand900),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.textError),
            child: Text(
              'Excluir',
              style: AppTextStyles.label.copyWith(color: AppColors.textError),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    await widget._mealService.softDeleteMeal(mealId: mealId);
    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(_record.copyWith(status: 'deleted'));
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
      return Image(
        image: CachedNetworkImageProvider(imageUrl!),
        fit: BoxFit.cover,
        width: double.infinity,
        gaplessPlayback: true,
        frameBuilder: (_, child, frame, wasSyncLoaded) {
          if (wasSyncLoaded || frame != null) {
            return child;
          }
          return const AppSkeletonBox(height: 250, borderRadius: 0);
        },
        errorBuilder: (_, __, ___) => _buildMissingImage(),
      );
    }

    if (imageAsset != null && imageAsset!.isNotEmpty) {
      return Image.asset(
        imageAsset!,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }

    return _buildMissingImage();
  }

  Widget _buildMissingImage() {
    return Container(
      color: AppColors.surfaceAlt,
      width: double.infinity,
      alignment: Alignment.center,
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
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
