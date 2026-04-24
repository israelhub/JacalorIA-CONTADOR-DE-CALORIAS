import 'dart:typed_data';

import '../helpers/food_review_helpers.dart';
import 'food_analysis_result.dart';

class FoodMealRecord {
  const FoodMealRecord({
    required this.imageBytes,
    required this.imageAsset,
    required this.title,
    required this.description,
    required this.kcalLabel,
    required this.timeLabel,
  });

  factory FoodMealRecord.fromAnalysis({
    Uint8List? imageBytes,
    required FoodAnalysisResult analysis,
    required DateTime recordedAt,
  }) {
    final foodNames = analysis.items
        .map((item) => item.name)
        .where((name) => name.trim().isNotEmpty)
        .take(3)
        .toList(growable: false);

    final description = foodNames.isEmpty
        ? 'Refeição analisada pela IA'
        : foodNames.join(', ');

    return FoodMealRecord(
      imageBytes: imageBytes,
      imageAsset: null,
      title: foodNames.isEmpty ? 'Refeição analisada' : foodNames.first,
      description: description,
      kcalLabel: '${analysis.totals.calories.round()} kcal',
      timeLabel: formatFoodReviewTime(recordedAt),
    );
  }

  final Uint8List? imageBytes;
  final String? imageAsset;
  final String title;
  final String description;
  final String kcalLabel;
  final String timeLabel;
}