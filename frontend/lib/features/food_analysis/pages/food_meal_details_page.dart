import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../shared/helpers/profile_value_helpers.dart';
import '../../../../shared/widgets/app_page_route.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_back_page_header.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/faded_meal_image.dart';
import '../../../../shared/widgets/macro_progress_indicator.dart';
import '../../home/services/meal_service.dart';
import '../../home/widgets/home_shell_layout.dart';
import '../helpers/food_review_helpers.dart';
import '../models/food_analysis_result.dart';
import '../models/food_meal_record.dart';
import '../models/saved_meal_template.dart';
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
    this.readOnly = false,
    MealService mealService = const MealService(),
    FoodAnalysisService analysisService = const FoodAnalysisService(),
    MealTemplateService templateService = const MealTemplateService(),
  }) : _mealService = mealService,
       _analysisService = analysisService,
       _templateService = templateService;

  final FoodMealRecord record;
  final Map<String, dynamic>? userProfile;
  final bool readOnly;
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
  bool _isSavedAsTemplate = false;
  String? _savedTemplateId;
  bool _wasEdited = false;
  bool _isClosing = false;

  static const Duration _sectionRevealDuration = Duration(milliseconds: 280);

  @override
  void initState() {
    super.initState();
    _record = widget.record;
    _sectionVisible = List<bool>.filled(3, false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_started) {
        _started = true;
        _revealSections();
        if (!widget.readOnly) {
          _syncSavedTemplateState();
        }
      }
    });
  }

  FoodMealRecord _mergeEditedRecord(FoodMealRecord updated) {
    final previous = _record;
    final resolvedImageUrl = (updated.imageUrl ?? '').trim().isNotEmpty
        ? updated.imageUrl
        : previous.imageUrl;

    return updated.copyWith(
      imageBytes: updated.imageBytes ?? previous.imageBytes,
      imageAsset: updated.imageAsset ?? previous.imageAsset,
      imageUrl: resolvedImageUrl,
      createdAt: updated.createdAt ?? previous.createdAt,
      items: updated.items.isNotEmpty ? updated.items : previous.items,
    );
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

    return PopScope<FoodMealRecord>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _isClosing) {
          return;
        }
        // canPop:false: o 1º Navigator.pop não fecha a rota — só chama este
        // callback. Precisamos re-popar preservando o result (ex.: deleted).
        _isClosing = true;
        final payload = result ?? (_wasEdited ? _record : null);
        Navigator.of(context).pop(payload);
      },
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        extendBodyBehindAppBar: true,
        appBar: FoodAnalysisPageHeader(
          title: 'Detalhes refeição',
          actions: widget.readOnly
              ? const []
              : [
                  IconButton(
                    tooltip: _isSavedAsTemplate
                        ? 'Remover das refeições salvas'
                        : 'Salvar para reutilizar',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 40,
                    ),
                    onPressed: _isSavingTemplate ? null : _handleSaveAsTemplate,
                    icon: _isSavingTemplate
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _isSavedAsTemplate
                                ? Icons.bookmark
                                : Icons.bookmark_add_outlined,
                            size: 22,
                            color: _isSavedAsTemplate
                                ? AppColors.brand900
                                : AppColors.brand900Variant,
                          ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    tooltip: 'Editar refeição',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 40,
                    ),
                    onPressed: _handleEditMeal,
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 22,
                      color: AppColors.brand900Variant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    tooltip: 'Excluir refeição',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 40,
                    ),
                    onPressed: _handleDeleteMeal,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 22,
                      color: AppColors.brand900Variant,
                    ),
                  ),
                ],
        ),
        body: AppBackPageContent(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontal,
              AppBackPageHeader.scrollTopInset(context, extra: AppSpacing.sm),
              AppSpacing.pageHorizontal,
              homeShellScrollBottomInset(context),
            ),
            children: [
              if (hasFadedMealImage(
                imageAsset: _record.imageAsset,
                imageBytes: _record.imageBytes,
                imageUrl: _record.imageUrl,
              )) ...[
                _RevealSection(
                  visible: _sectionVisible[0],
                  duration: _sectionRevealDuration,
                  child: _MealHeroImage(
                    imageBytes: _record.imageBytes,
                    imageAsset: _record.imageAsset,
                    imageUrl: _record.imageUrl,
                  ),
                ),
                const SizedBox(height: AppSpacing.cardGap),
              ],
              _RevealSection(
                visible: _sectionVisible[1],
                duration: _sectionRevealDuration,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
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
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.insetSurface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
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
                                    labelStyle: AppTextStyles.bodyMedium
                                        .copyWith(
                                          color: AppColors.brand900Variant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                    valueStyle: AppTextStyles.captionStrong
                                        .copyWith(
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
                                    labelStyle: AppTextStyles.bodyMedium
                                        .copyWith(
                                          color: AppColors.brand900Variant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                    valueStyle: AppTextStyles.captionStrong
                                        .copyWith(
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
                                    labelStyle: AppTextStyles.bodyMedium
                                        .copyWith(
                                          color: AppColors.brand900Variant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                    valueStyle: AppTextStyles.captionStrong
                                        .copyWith(
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.cardGap),
              _RevealSection(
                visible: _sectionVisible[2],
                duration: _sectionRevealDuration,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
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
                                FoodMealItemRow(
                                  item: item,
                                  mealProtein: _record.protein,
                                  mealCarbs: _record.carbs,
                                  mealFat: _record.fat,
                                ),
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
      ),
    );
  }

  Future<void> _syncSavedTemplateState() async {
    try {
      final templates = await widget._templateService.fetchTemplates();
      if (!mounted) {
        return;
      }

      final match = _findMatchingTemplate(templates);
      setState(() {
        _isSavedAsTemplate = match != null;
        _savedTemplateId = match?.id;
      });
    } catch (_) {}
  }

  SavedMealTemplate? _findMatchingTemplate(List<SavedMealTemplate> templates) {
    for (final template in templates) {
      if (_matchesSavedTemplate(template)) {
        return template;
      }
    }
    return null;
  }

  bool _matchesSavedTemplate(SavedMealTemplate template) {
    final sameMacros =
        template.calories == _record.calories &&
        template.protein == _record.protein &&
        template.carbs == _record.carbs &&
        template.fat == _record.fat;
    if (!sameMacros) {
      return false;
    }

    final sameTitle =
        template.title.trim().toLowerCase() ==
        _record.title.trim().toLowerCase();
    if (!sameTitle) {
      return false;
    }

    if (template.items.length != _record.items.length) {
      return false;
    }

    for (var index = 0; index < template.items.length; index++) {
      final savedItem = template.items[index];
      final mealItem = _record.items[index];
      if (savedItem.name.trim().toLowerCase() !=
              mealItem.name.trim().toLowerCase() ||
          savedItem.grams != mealItem.grams) {
        return false;
      }
    }

    return true;
  }

  Future<void> _handleSaveAsTemplate() async {
    if (_isSavingTemplate) {
      return;
    }

    if (_isSavedAsTemplate) {
      await _handleRemoveSavedTemplate();
      return;
    }

    setState(() => _isSavingTemplate = true);

    try {
      final saved = await widget._templateService.saveFromMeal(_record);
      if (!mounted) {
        return;
      }

      setState(() {
        _isSavedAsTemplate = true;
        _savedTemplateId = saved.id;
      });

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

  Future<void> _handleRemoveSavedTemplate() async {
    final templateId = (_savedTemplateId ?? '').trim();
    if (templateId.isEmpty) {
      return;
    }

    setState(() => _isSavingTemplate = true);

    try {
      await widget._templateService.deleteTemplate(templateId: templateId);
      if (!mounted) {
        return;
      }

      setState(() {
        _isSavedAsTemplate = false;
        _savedTemplateId = null;
      });

      AppToast.success(context, message: 'Refeição removida das salvas.');
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

    final updatedMeal = await context.pushSlidePage<FoodMealRecord>(
      FoodReviewPage(
        imageBytes: _record.imageBytes,
        imageAsset: _record.imageAsset,
        imageUrl: _record.imageUrl,
        analysis: analysis,
        analysisService: widget._analysisService,
        mealService: widget._mealService,
        existingMealId: mealId,
        initialMealTitle: _record.title,
        initialTimeLabel: _record.timeLabel,
        initialMealType: _record.mealType,
        recordedAt: _record.createdAt,
        showDetailsAfterSave: false,
      ),
      rootNavigator: true,
    );

    if (!mounted || updatedMeal == null) {
      return;
    }

    setState(() {
      _record = _mergeEditedRecord(updatedMeal);
      _wasEdited = true;
      _isSavedAsTemplate = false;
      _savedTemplateId = null;
    });
    await _syncSavedTemplateState();
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

    // canPop:false — o PopScope re-popará preservando este result.
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
    final screenHeight = MediaQuery.sizeOf(context).height;
    final heroHeight = (screenHeight * 0.38).clamp(300.0, 420.0);

    return SizedBox(
      height: heroHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: FadedMealImage(
          imageAsset: imageAsset,
          imageBytes: imageBytes,
          imageUrl: imageUrl,
        ),
      ),
    );
  }
}
