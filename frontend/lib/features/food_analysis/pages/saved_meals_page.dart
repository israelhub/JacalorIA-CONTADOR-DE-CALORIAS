import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_back_page_header.dart';
import '../../../shared/widgets/app_page_route.dart';
import '../../../shared/widgets/faded_meal_image.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../home/widgets/home_meal_card.dart';
import '../helpers/food_review_helpers.dart';
import '../models/food_meal_record.dart';
import '../models/saved_meal_template.dart';
import '../services/food_analysis_service.dart';
import '../services/meal_template_service.dart';
import '../widgets/food_analysis_page_header.dart';
import '../widgets/food_meal_type_chips.dart';
import 'food_review_page.dart';

class SavedMealsPage extends StatefulWidget {
  const SavedMealsPage({
    super.key,
    this.recordedAt,
    MealTemplateService templateService = const MealTemplateService(),
    FoodAnalysisService analysisService = const FoodAnalysisService(),
  }) : _templateService = templateService,
       _analysisService = analysisService;

  final DateTime? recordedAt;
  final MealTemplateService _templateService;
  final FoodAnalysisService _analysisService;

  @override
  State<SavedMealsPage> createState() => _SavedMealsPageState();
}

class _SavedMealsPageState extends State<SavedMealsPage> {
  late Future<List<SavedMealTemplate>> _templatesFuture;
  FoodMealType? _selectedMealType;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _templatesFuture = widget._templateService.fetchTemplates();
  }

  void _reload() {
    setState(() {
      _templatesFuture = widget._templateService.fetchTemplates();
    });
  }

  Future<void> _useTemplate(SavedMealTemplate template) async {
    if (_isBusy) {
      return;
    }

    setState(() => _isBusy = true);

    try {
      final meal = await context.pushSlidePage<FoodMealRecord>(
        FoodReviewPage(
          imageBytes: null,
          imageUrl: template.imageUrl,
          analysis: template.toAnalysis(),
          analysisService: widget._analysisService,
          initialMealTitle: template.title,
          initialMealType: template.mealType,
          recordedAt: widget.recordedAt,
        ),
      );

      if (!mounted) {
        return;
      }

      if (meal != null) {
        Navigator.of(context).pop(meal);
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _deleteTemplate(SavedMealTemplate template) async {
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
          'Remover refeição salva',
          style: AppTextStyles.homeSectionTitle.copyWith(
            color: AppColors.brand900Variant,
          ),
        ),
        content: Text(
          'Essa refeição sairá da sua lista de refeições salvas.',
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
              'Remover',
              style: AppTextStyles.label.copyWith(color: AppColors.textError),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    try {
      await widget._templateService.deleteTemplate(templateId: template.id);
      if (!mounted) {
        return;
      }
      _reload();
      AppToast.success(context, message: 'Refeição removida das salvas');
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppToast.error(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      extendBodyBehindAppBar: true,
      appBar: const FoodAnalysisPageHeader(title: 'Refeições salvas'),
      body: AppBackPageContent(
        child: FutureBuilder<List<SavedMealTemplate>>(
          future: _templatesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const AppSkeletonList(
                itemCount: 3,
                itemHeight: HomeMealCard.defaultHeight,
                borderRadius: AppRadius.lg,
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pageHorizontal,
                    vertical: AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        snapshot.error.toString().replaceFirst(
                          'Exception: ',
                          '',
                        ),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textError,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextButton(
                        onPressed: _reload,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final templates = snapshot.data ?? const <SavedMealTemplate>[];
            if (templates.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bookmark_border,
                        size: 48,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Nenhuma refeição salva',
                        style: AppTextStyles.homeSectionTitle.copyWith(
                          color: AppColors.brand900Variant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Abra os detalhes de uma refeição e toque em salvar para reutilizá-la depois.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final selectedType = _selectedMealType;
            final filtered = selectedType == null
                ? templates
                : templates
                      .where((template) => template.mealType == selectedType)
                      .toList(growable: false);

            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.sm,
                AppSpacing.pageHorizontal,
                AppSpacing.xxl,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FoodMealTypeChips(
                      selected: _selectedMealType,
                      includeAll: true,
                      onSelected: (type) {
                        setState(() => _selectedMealType = type);
                      },
                      keyPrefix: 'saved-meals-filter',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                selectedType == null
                                    ? 'Nenhuma refeição salva'
                                    : 'Nenhuma refeição salva de ${selectedType.chipLabel.toLowerCase()}',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppSpacing.md),
                              itemBuilder: (context, index) {
                                final template = filtered[index];
                                return _SavedMealCard(
                                  template: template,
                                  enabled: !_isBusy,
                                  onTap: () => _useTemplate(template),
                                  onDelete: () => _deleteTemplate(template),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SavedMealCard extends StatelessWidget {
  const _SavedMealCard({
    required this.template,
    required this.enabled,
    required this.onTap,
    required this.onDelete,
  });

  final SavedMealTemplate template;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  static const _height = HomeMealCard.defaultHeight;
  static const _imagePadding = HomeMealCard.imagePadding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg - AppSpacing.xs);
    final imageSize = _height - (_imagePadding * 2);
    final imageUrl = template.imageUrl;
    final hasImage = hasFadedMealImage(
      imageAsset: null,
      imageBytes: null,
      imageUrl: imageUrl,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: radius,
        child: Container(
          width: double.infinity,
          height: _height,
          decoration: BoxDecoration(
            color: AppColors.insetSurface,
            borderRadius: radius,
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(_imagePadding),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: SizedBox(
                    width: imageSize,
                    height: imageSize,
                    child: hasImage
                        ? FadedMealImage(imageUrl: imageUrl)
                        : const MealImageFallback(),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              template.title,
                              style: AppTextStyles.homeMealTitle.copyWith(
                                color: AppColors.brand900Variant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.xs - 2),
                            Text(
                              template.description,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.xs - 2),
                            Text(
                              template.kcalLabel,
                              style: AppTextStyles.captionStrong.copyWith(
                                color: AppColors.brand900Variant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remover',
                        onPressed: enabled ? onDelete : null,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.foodReviewDeleteIcon,
                        ),
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
}
