import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_page_route.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../models/food_meal_record.dart';
import '../models/saved_meal_template.dart';
import '../services/food_analysis_service.dart';
import '../services/meal_template_service.dart';
import '../widgets/food_analysis_page_header.dart';
import 'food_review_page.dart';

class SavedMealsPage extends StatefulWidget {
  const SavedMealsPage({
    super.key,
    MealTemplateService templateService = const MealTemplateService(),
    FoodAnalysisService analysisService = const FoodAnalysisService(),
  }) : _templateService = templateService,
       _analysisService = analysisService;

  final MealTemplateService _templateService;
  final FoodAnalysisService _analysisService;

  @override
  State<SavedMealsPage> createState() => _SavedMealsPageState();
}

class _SavedMealsPageState extends State<SavedMealsPage> {
  late Future<List<SavedMealTemplate>> _templatesFuture;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refeição removida das salvas')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const FoodAnalysisPageHeader(title: 'Refeições salvas'),
      body: SafeArea(
        child: FutureBuilder<List<SavedMealTemplate>>(
          future: _templatesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    AppSkeletonBox(height: 88, borderRadius: 12),
                    SizedBox(height: AppSpacing.md),
                    AppSkeletonBox(height: 88, borderRadius: 12),
                    SizedBox(height: AppSpacing.md),
                    AppSkeletonBox(height: 88, borderRadius: 12),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
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

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              itemCount: templates.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final template = templates[index];
                return _SavedMealCard(
                  template: template,
                  enabled: !_isBusy,
                  onTap: () => _useTemplate(template),
                  onDelete: () => _deleteTemplate(template),
                );
              },
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.lg - AppSpacing.xs),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg - 2,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.homeCardSurface,
            borderRadius: BorderRadius.circular(AppRadius.lg - AppSpacing.xs),
            border: Border.all(color: AppColors.homeMealCardBorder),
            boxShadow: AppShadows.homeMealCard,
          ),
          child: Row(
            children: [
              Container(
                width: AppSpacing.huge + AppSpacing.xs,
                height: AppSpacing.huge + AppSpacing.xs,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.brand300),
                ),
                child: template.imageUrl != null
                    ? Image(
                        image: CachedNetworkImageProvider(template.imageUrl!),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: AppColors.homeMetaCardSurface,
                          child: Icon(
                            Icons.restaurant_outlined,
                            color: AppColors.action500,
                          ),
                        ),
                      )
                    : const ColoredBox(
                        color: AppColors.homeMetaCardSurface,
                        child: Icon(
                          Icons.restaurant_outlined,
                          color: AppColors.action500,
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.foodReviewDeleteIcon,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
