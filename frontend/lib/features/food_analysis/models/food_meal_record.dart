import 'dart:typed_data';

import '../helpers/food_review_helpers.dart';
import 'food_analysis_result.dart';

class FoodMealRecord {
  const FoodMealRecord({
    this.id,
    required this.imageBytes,
    required this.imageAsset,
    this.imageUrl,
    this.createdAt,
    required this.title,
    required this.description,
    required this.kcalLabel,
    required this.timeLabel,
    this.mealType = FoodMealType.free,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.items,
    this.status = 'active',
  });

  factory FoodMealRecord.fromAnalysis({
    String? id,
    Uint8List? imageBytes,
    String? imageUrl,
    required FoodAnalysisResult analysis,
    required DateTime recordedAt,
    String? titleOverride,
    String? timeLabelOverride,
    FoodMealType? mealTypeOverride,
  }) {
    final foodNames = analysis.items
        .map((item) => item.name)
        .where((name) => name.trim().isNotEmpty)
        .take(3)
        .toList(growable: false);

    final description = foodNames.isEmpty
        ? 'Refeição analisada pela IA'
        : foodNames.join(', ');

    final resolvedTitle = (titleOverride ?? '').trim();
    final resolvedTimeLabel = (timeLabelOverride ?? '').trim();
    final resolvedMealType =
        mealTypeOverride ??
        suggestMealType(
          recordedAt: recordedAt,
          foodNames: analysis.items.map((item) => item.name).toList(),
          titleHint: resolvedTitle,
        );

    return FoodMealRecord(
      id: id,
      imageBytes: imageBytes,
      imageAsset: null,
      imageUrl: imageUrl,
      createdAt: recordedAt,
      title: resolvedTitle.isNotEmpty
          ? resolvedTitle
          : (foodNames.isEmpty ? 'Refeição analisada' : foodNames.first),
      description: description,
      kcalLabel: '${analysis.totals.calories.round()} kcal',
      timeLabel: resolvedTimeLabel.isNotEmpty
          ? resolvedTimeLabel
          : formatFoodReviewTime(recordedAt),
      mealType: resolvedMealType,
      calories: analysis.totals.calories.round(),
      protein: analysis.totals.protein.round(),
      carbs: analysis.totals.carbs.round(),
      fat: analysis.totals.fat.round(),
      items: analysis.items.toList(growable: false),
      status: 'active',
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
    final title = json['title'] as String? ?? 'Refeição';
    final mealTypeRaw = json['mealType'] ?? json['meal_type'];
    final mealType = mealTypeRaw != null
        ? foodMealTypeFromApi(mealTypeRaw as String?)
        : foodMealTypeFromTitle(title);

    return FoodMealRecord(
      id: json['id'] as String?,
      imageBytes: null,
      imageAsset: isNetwork ? null : _asAssetPath(imageUrl),
      imageUrl: isNetwork ? imageUrl : null,
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      title: title,
      description: json['description'] as String? ?? '',
      kcalLabel: '${_asRoundedInt(json['calories'])} kcal',
      timeLabel: json['timeLabel'] as String? ?? '12:00',
      mealType: mealType,
      calories: _asRoundedInt(json['calories']),
      protein: _asRoundedInt(json['protein']),
      carbs: _asRoundedInt(json['carbs']),
      fat: _asRoundedInt(json['fat']),
      items: items,
      status: (json['status'] as String? ?? 'active').trim().toLowerCase(),
    );
  }

  final String? id;
  final Uint8List? imageBytes;
  final String? imageAsset;
  final String? imageUrl;
  final DateTime? createdAt;
  final String title;
  final String description;
  final String kcalLabel;
  final String timeLabel;
  final FoodMealType mealType;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final List<FoodAnalysisItem> items;
  final String status;

  FoodMealRecord copyWith({
    String? id,
    Uint8List? imageBytes,
    String? imageAsset,
    String? imageUrl,
    DateTime? createdAt,
    String? title,
    String? description,
    String? kcalLabel,
    String? timeLabel,
    FoodMealType? mealType,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    List<FoodAnalysisItem>? items,
    String? status,
  }) {
    return FoodMealRecord(
      id: id ?? this.id,
      imageBytes: imageBytes ?? this.imageBytes,
      imageAsset: imageAsset ?? this.imageAsset,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      description: description ?? this.description,
      kcalLabel: kcalLabel ?? this.kcalLabel,
      timeLabel: timeLabel ?? this.timeLabel,
      mealType: mealType ?? this.mealType,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      items: items ?? this.items,
      status: status ?? this.status,
    );
  }
}

int _asRoundedInt(Object? value) {
  if (value is num) {
    return value.round();
  }

  if (value is String) {
    final parsed = num.tryParse(value.replaceAll(',', '.'));
    if (parsed != null) {
      return parsed.round();
    }
  }

  return 0;
}

String? _asAssetPath(String? value) {
  final raw = (value ?? '').trim();
  if (raw.startsWith('assets/')) {
    return raw;
  }

  return null;
}

DateTime? _parseDateTime(Object? value) {
  if (value is DateTime) {
    return value.toLocal();
  }

  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toLocal();
  }

  return null;
}
