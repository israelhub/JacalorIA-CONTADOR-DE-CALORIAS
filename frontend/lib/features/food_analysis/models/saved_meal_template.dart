import '../helpers/food_review_helpers.dart';
import 'food_analysis_result.dart';

class SavedMealTemplate {
  const SavedMealTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.items,
    this.imageUrl,
    this.createdAt,
  });

  factory SavedMealTemplate.fromJson(Map<String, dynamic> json) {
    final imageUrl = json['imageUrl'] as String?;
    final isNetwork =
        imageUrl != null &&
        (imageUrl.startsWith('http') || imageUrl.startsWith('https'));
    final items = (json['analysisItems'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(FoodAnalysisItem.fromJson)
        .toList(growable: false);

    return SavedMealTemplate(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Refeição',
      description: json['description'] as String? ?? '',
      calories: _asRoundedInt(json['calories']),
      protein: _asRoundedInt(json['protein']),
      carbs: _asRoundedInt(json['carbs']),
      fat: _asRoundedInt(json['fat']),
      items: items,
      imageUrl: isNetwork ? imageUrl : null,
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

  final String id;
  final String title;
  final String description;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final List<FoodAnalysisItem> items;
  final String? imageUrl;
  final DateTime? createdAt;

  FoodAnalysisResult toAnalysis() {
    return FoodAnalysisResult(
      items: items,
      totals: FoodAnalysisTotals(
        calories: calories.toDouble(),
        protein: protein.toDouble(),
        carbs: carbs.toDouble(),
        fat: fat.toDouble(),
      ),
      justification: 'Refeição salva reutilizada',
    );
  }

  String get kcalLabel => '$calories kcal';

  String get timeLabel {
    final at = createdAt;
    if (at == null) {
      return '';
    }
    return formatFoodReviewTime(at);
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

DateTime? _parseDateTime(Object? value) {
  if (value is DateTime) {
    return value;
  }

  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }

  return null;
}
