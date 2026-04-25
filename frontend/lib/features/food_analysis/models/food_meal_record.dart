import 'dart:typed_data';

import '../helpers/food_review_helpers.dart';
import 'food_analysis_result.dart';

class FoodMealRecord {
  const FoodMealRecord({
    required this.imageBytes,
    required this.imageAsset,
    this.imageUrl,
    this.createdAt,
    required this.title,
    required this.description,
    required this.kcalLabel,
    required this.timeLabel,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.items,
  });

  factory FoodMealRecord.fromAnalysis({
    Uint8List? imageBytes,
    String? imageUrl,
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
      imageUrl: imageUrl,
      createdAt: recordedAt,
      title: foodNames.isEmpty ? 'Refeição analisada' : foodNames.first,
      description: description,
      kcalLabel: '${analysis.totals.calories.round()} kcal',
      timeLabel: formatFoodReviewTime(recordedAt),
      calories: analysis.totals.calories.round(),
      protein: analysis.totals.protein.round(),
      carbs: analysis.totals.carbs.round(),
      fat: analysis.totals.fat.round(),
      items: analysis.items.toList(growable: false),
    );
  }

  factory FoodMealRecord.fromJson(Map<String, dynamic> json) {
    final imageUrl = json['imageUrl'] as String?;
    final isNetwork =
        imageUrl != null &&
        (imageUrl.startsWith('http') || imageUrl.startsWith('https'));
    final items = (json['analysisItems'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(FoodAnalysisItem.fromJson)
        .toList(growable: false);

    return FoodMealRecord(
      imageBytes: null,
      imageAsset: isNetwork
          ? null
          : (imageUrl ??
                'assets/images/smiling green cartoon crocodile@2x.webp'),
      imageUrl: isNetwork ? imageUrl : null,
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      title: json['title'] as String? ?? 'Refeição',
      description: json['description'] as String? ?? '',
      kcalLabel: '${(json['calories'] as num?)?.round() ?? 0} kcal',
      timeLabel: json['timeLabel'] as String? ?? '12:00',
      calories: (json['calories'] as num?)?.round() ?? 0,
      protein: (json['protein'] as num?)?.round() ?? 0,
      carbs: (json['carbs'] as num?)?.round() ?? 0,
      fat: (json['fat'] as num?)?.round() ?? 0,
      items: items,
    );
  }

  final Uint8List? imageBytes;
  final String? imageAsset;
  final String? imageUrl;
  final DateTime? createdAt;
  final String title;
  final String description;
  final String kcalLabel;
  final String timeLabel;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final List<FoodAnalysisItem> items;
}

DateTime? _parseDateTime(Object? value) {
  if (value is DateTime) {
    return value;
  }

  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }

  return null;
}
