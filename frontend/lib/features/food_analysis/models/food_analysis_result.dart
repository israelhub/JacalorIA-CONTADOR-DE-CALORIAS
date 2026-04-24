import 'dart:convert';

class FoodAnalysisItem {
  const FoodAnalysisItem({
    required this.name,
    required this.grams,
    required this.calories,
    this.unit = 'g',
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final String name;
  final int grams;
  final double calories;
  final String unit;
  final double protein;
  final double carbs;
  final double fat;

  factory FoodAnalysisItem.fromJson(Map<String, dynamic> json) {
    return FoodAnalysisItem(
      name: (json['name'] as String? ?? '').trim(),
      grams: _asInt(json['grams']),
      calories: _asDouble(json['calories']),
      unit: ((json['unit'] as String?)?.trim().toLowerCase().isNotEmpty ?? false)
          ? (json['unit'] as String).trim().toLowerCase()
          : 'g',
      protein: _asDouble(json['protein']),
      carbs: _asDouble(json['carbs']),
      fat: _asDouble(json['fat']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'grams': grams,
      'calories': calories,
      'unit': unit,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  String signature() {
    return '${name.trim().toLowerCase()}|$grams|${unit.trim().toLowerCase()}';
  }

  Map<String, dynamic> toReanalysisJson() => <String, dynamic>{
        'name': name,
        'grams': grams,
        'unit': unit,
      };

  static int _asInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.round();
    }

    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.round() ?? 0;
    }

    return 0;
  }

  static double _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    }

    return 0;
  }
}

class FoodAnalysisTotals {
  const FoodAnalysisTotals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  factory FoodAnalysisTotals.fromJson(Map<String, dynamic> json) {
    return FoodAnalysisTotals(
      calories: FoodAnalysisItem._asDouble(json['calories']),
      protein: FoodAnalysisItem._asDouble(json['protein']),
      carbs: FoodAnalysisItem._asDouble(json['carbs']),
      fat: FoodAnalysisItem._asDouble(json['fat']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}

class FoodAnalysisResult {
  const FoodAnalysisResult({
    required this.items,
    required this.totals,
    required this.justification,
  });

  final List<FoodAnalysisItem> items;
  final FoodAnalysisTotals totals;
  final String justification;

  factory FoodAnalysisResult.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(FoodAnalysisItem.fromJson)
        .toList(growable: false);

    final totalsJson = json['totals'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return FoodAnalysisResult(
      items: items,
      totals: FoodAnalysisTotals.fromJson(totalsJson),
      justification: (json['justification'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'items': items.map((item) => item.toJson()).toList(growable: false),
      'totals': totals.toJson(),
      'justification': justification,
    };
  }

  String itemsSignature() {
    return items.map((item) => item.signature()).join('|');
  }

  String toEncodedJson() => jsonEncode(toJson());
}