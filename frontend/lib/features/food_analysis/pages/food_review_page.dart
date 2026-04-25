import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../home/services/meal_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_page_route.dart';
import '../helpers/food_review_helpers.dart';
import '../models/food_analysis_result.dart';
import '../models/food_meal_record.dart';
import '../services/food_analysis_service.dart';
import 'food_analysis_processing_page.dart';
import 'food_meal_details_page.dart';
import '../widgets/food_analysis_page_header.dart';
import '../widgets/food_review_add_item_button.dart';
import '../widgets/food_review_ai_title.dart';
import '../widgets/food_review_confirm_button.dart';
import '../widgets/food_review_item_row.dart';
import '../widgets/food_review_meal_header.dart';

class FoodReviewPage extends StatefulWidget {
  const FoodReviewPage({
    super.key,
    required this.imageBytes,
    required this.analysis,
    required this.analysisService,
  });

  final Uint8List? imageBytes;
  final FoodAnalysisResult analysis;
  final FoodAnalysisService analysisService;

  @override
  State<FoodReviewPage> createState() => _FoodReviewPageState();
}

class _FoodReviewPageState extends State<FoodReviewPage> {
  late final GlobalKey<AnimatedListState> _itemsListKey;
  late final List<_ReviewItemEntry> _items;
  late FoodAnalysisResult _analysis;
  late String _confirmedSignature;
  late final String _mealTitle;
  late final DateTime _recordedAt;
  late final String _previewTime;
  final _mealService = const MealService();
  bool _isBusy = false;
  String? _error;
  int _nextItemId = 0;

  static const Duration _itemInsertDuration = Duration(milliseconds: 220);
  static const Duration _itemRemoveDuration = Duration(milliseconds: 180);

  bool get _hasChanges => _currentSignature != _confirmedSignature;

  String get _currentSignature {
    return _currentItems.map((item) => item.signature()).join('|');
  }

  List<FoodAnalysisItem> get _currentItems {
    return List<FoodAnalysisItem>.generate(_items.length, (index) {
      final item = _items[index];
      final measurement = parseFoodMeasurement(item.measurementController.text);

      return FoodAnalysisItem(
        name: item.nameController.text.trim(),
        grams: measurement.grams,
        unit: measurement.unit,
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _analysis = widget.analysis;
    _confirmedSignature = widget.analysis.itemsSignature();
    _mealTitle = foodReviewMealTitleFromNow();
    _recordedAt = DateTime.now();
    _previewTime = formatFoodReviewTime(_recordedAt);
    _itemsListKey = GlobalKey<AnimatedListState>();
    _items = widget.analysis.items.map(_createEntry).toList(growable: true);
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const FoodAnalysisPageHeader(title: 'Revisar análise'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                children: [
                  FoodReviewMealHeader(
                    imageBytes: widget.imageBytes,
                    title: _mealTitle,
                    timeLabel: _previewTime,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Divider(
                    key: ValueKey('food-review-main-divider'),
                    color: AppColors.divider,
                    height: 1,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const FoodReviewAiTitle(),
                  const SizedBox(height: AppSpacing.xl),
                  AnimatedList(
                    key: _itemsListKey,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    initialItemCount: _items.length,
                    itemBuilder: (context, index, animation) {
                      final item = _items[index];

                      return _AnimatedFoodReviewRow(
                        animation: animation,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                          child: FoodReviewItemRow(
                            key: ValueKey(item.id),
                            index: index,
                            nameController: item.nameController,
                            measurementController: item.measurementController,
                            onRemove: _items.length > 1
                                ? () => _removeItem(index)
                                : null,
                            onChanged: () {
                              setState(() {
                                _error = null;
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  FoodReviewAddItemButton(onTap: _isBusy ? null : _addItem),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _error!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textError,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: FoodReviewConfirmButton(
          isBusy: _isBusy,
          onTap: _isBusy ? null : _submit,
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      await _saveAndOpenDetails();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isBusy = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _addItem() {
    final index = _items.length;

    setState(() {
      _items.add(
        _createEntry(
          const FoodAnalysisItem(
            name: 'Novo alimento',
            grams: 100,
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
          ),
        ),
      );
      _error = null;
    });

    _itemsListKey.currentState?.insertItem(
      index,
      duration: _itemInsertDuration,
    );
  }

  void _removeItem(int index) {
    final removedItem = _items.removeAt(index);

    setState(() {
      _error = null;
    });

    _itemsListKey.currentState?.removeItem(
      index,
      (context, animation) => _AnimatedFoodReviewRow(
        animation: animation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          child: FoodReviewItemRow(
            index: index,
            nameController: removedItem.nameController,
            measurementController: removedItem.measurementController,
            onRemove: null,
            onChanged: () {},
          ),
        ),
      ),
      duration: _itemRemoveDuration,
    );

    Future<void>.delayed(_itemRemoveDuration).then((_) {
      removedItem.dispose();
    });
  }

  _ReviewItemEntry _createEntry(FoodAnalysisItem item) {
    return _ReviewItemEntry(
      id: _nextItemId++,
      nameController: TextEditingController(text: item.name),
      measurementController: TextEditingController(
        text: '${item.grams} ${item.unit}',
      ),
    );
  }

  Future<void> _saveAndOpenDetails(
  ) async {
    final currentItems = _currentItems;
    final shouldReanalyze = _hasChanges;

    final savedAnalysis = await context.pushSlidePage<FoodAnalysisResult>(
      FoodAnalysisProcessingPage(
        imageBytes: widget.imageBytes,
        appBarTitle: 'Detalhes da refeição',
        title: 'Carregando calorias...',
        message: 'Estamos salvando e atualizando os dados nutricionais.',
        statusIcon: Icons.local_fire_department,
        showScanner: false,
        operation: () async {
          final analysisToSave = shouldReanalyze
              ? await widget.analysisService.recalculate(items: currentItems)
              : _analysis;

          final mealRecordToSave = FoodMealRecord.fromAnalysis(
            imageBytes: widget.imageBytes,
            analysis: analysisToSave,
            recordedAt: _recordedAt,
          );

          await _mealService.saveMeal(
            record: mealRecordToSave,
            analysis: analysisToSave,
          );

          return analysisToSave;
        },
      ),
    );

    if (savedAnalysis == null) {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _error = 'Não foi possível carregar os detalhes da refeição.';
        });
      }
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _analysis = savedAnalysis;
      _confirmedSignature = _currentSignature;
      _isBusy = false;
    });

    final mealRecord = FoodMealRecord.fromAnalysis(
      imageBytes: widget.imageBytes,
      analysis: savedAnalysis,
      recordedAt: _recordedAt,
    );

    final confirmedMeal = await context.pushSlidePage<FoodMealRecord>(
      FoodMealDetailsPage(record: mealRecord),
    );

    if (mounted) {
      Navigator.of(context).pop(confirmedMeal ?? mealRecord);
    }
  }
}

class _ReviewItemEntry {
  _ReviewItemEntry({
    required this.id,
    required this.nameController,
    required this.measurementController,
  });

  final int id;
  final TextEditingController nameController;
  final TextEditingController measurementController;

  void dispose() {
    nameController.dispose();
    measurementController.dispose();
  }
}

class _AnimatedFoodReviewRow extends StatelessWidget {
  const _AnimatedFoodReviewRow({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );

    return FadeTransition(
      opacity: curvedAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.08),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: SizeTransition(
          sizeFactor: curvedAnimation,
          axisAlignment: -1,
          child: child,
        ),
      ),
    );
  }
}
