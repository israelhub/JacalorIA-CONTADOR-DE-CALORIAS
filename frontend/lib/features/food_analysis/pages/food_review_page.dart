import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../helpers/food_review_helpers.dart';
import '../models/food_analysis_result.dart';
import '../models/food_meal_record.dart';
import '../services/food_analysis_service.dart';
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
  late final List<TextEditingController> _nameControllers;
  late final List<TextEditingController> _quantityControllers;
  late final List<TextEditingController> _unitControllers;
  late FoodAnalysisResult _analysis;
  late String _confirmedSignature;
  late final String _mealTitle;
  late final String _previewTime;
  bool _isBusy = false;
  String? _error;

  bool get _hasChanges => _currentSignature != _confirmedSignature;

  String get _currentSignature {
    return _currentItems.map((item) => item.signature()).join('|');
  }

  List<FoodAnalysisItem> get _currentItems {
    return List<FoodAnalysisItem>.generate(_nameControllers.length, (index) {
      final grams = int.tryParse(_quantityControllers[index].text.trim()) ?? 0;
      final unit = _unitControllers[index].text.trim().toLowerCase();

      return FoodAnalysisItem(
        name: _nameControllers[index].text.trim(),
        grams: grams,
        unit: unit.isEmpty ? 'g' : unit,
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
    _previewTime = formatFoodReviewTime(DateTime.now());
    _nameControllers = widget.analysis.items
        .map((item) => TextEditingController(text: item.name))
        .toList();
    _quantityControllers = widget.analysis.items
        .map((item) => TextEditingController(text: item.grams.toString()))
        .toList();
    _unitControllers = widget.analysis.items
        .map((item) => TextEditingController(text: item.unit))
        .toList();
  }

  @override
  void dispose() {
    for (final controller in _nameControllers) {
      controller.dispose();
    }
    for (final controller in _quantityControllers) {
      controller.dispose();
    }

    for (final controller in _unitControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceAlt,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Text(
          'Revisar análise',
          style: AppTextStyles.homeSectionTitle.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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
                  ...List<Widget>.generate(
                    _nameControllers.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                      child: FoodReviewItemRow(
                        index: index,
                        nameController: _nameControllers[index],
                        quantityController: _quantityControllers[index],
                        unitController: _unitControllers[index],
                        onRemove: _nameControllers.length > 1
                            ? () => _removeItem(index)
                            : null,
                        onChanged: () {
                          setState(() {
                            _error = null;
                          });
                        },
                      ),
                    ),
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
    final items = _currentItems;

    if (_hasChanges) {
      setState(() {
        _isBusy = true;
        _error = null;
      });

      try {
        final recalculated = await widget.analysisService.recalculate(
          items: items,
        );

        if (!mounted) {
          return;
        }

        setState(() {
          _analysis = recalculated;
          _confirmedSignature = _currentSignature;
          _isBusy = false;
        });
      } catch (error) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isBusy = false;
          _error = error.toString().replaceFirst('Exception: ', '');
        });
      }

      return;
    }

    final mealRecord = FoodMealRecord.fromAnalysis(
      imageBytes: widget.imageBytes,
      analysis: _analysis,
      recordedAt: DateTime.now(),
    );

    if (mounted) {
      Navigator.of(context).pop(mealRecord);
    }
  }

  void _addItem() {
    setState(() {
      _nameControllers.add(TextEditingController(text: 'Novo alimento'));
      _quantityControllers.add(TextEditingController(text: '100'));
      _unitControllers.add(TextEditingController(text: 'g'));
      _error = null;
    });
  }

  void _removeItem(int index) {
    setState(() {
      _nameControllers[index].dispose();
      _quantityControllers[index].dispose();
      _unitControllers[index].dispose();
      _nameControllers.removeAt(index);
      _quantityControllers.removeAt(index);
      _unitControllers.removeAt(index);
      _error = null;
    });
  }
}
