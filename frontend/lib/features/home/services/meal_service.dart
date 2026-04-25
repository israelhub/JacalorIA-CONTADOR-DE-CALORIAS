import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../auth/service/auth_service.dart';
import '../../../shared/services/supabase_storage_service.dart';
import '../../food_analysis/models/food_meal_record.dart';
import '../../food_analysis/models/food_analysis_result.dart';

import '../../../core/config/api_config.dart';

class MealService {
  const MealService();

  static String get _baseUrl => ApiConfig.baseUrl;

  Map<String, String> _buildHeaders({bool withJsonContentType = false}) {
    final headers = <String, String>{};

    if (withJsonContentType) {
      headers['Content-Type'] = 'application/json';
    }

    final token = AuthService.globalToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
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

  Future<List<FoodMealRecord>> fetchMeals() async {
    final uri = Uri.parse('$_baseUrl/meals');
    final response = await http.get(uri, headers: _buildHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) {
        final imageUrl = json['imageUrl'] as String?;
        final isNetwork =
            imageUrl != null &&
            (imageUrl.startsWith('http') || imageUrl.startsWith('https'));
        final items = (json['analysisItems'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map((item) => FoodAnalysisItem.fromJson(item))
            .toList(growable: false);

        return FoodMealRecord(
          imageBytes: null,
          imageUrl: isNetwork ? imageUrl : null,
          imageAsset: !isNetwork
              ? (imageUrl ??
                    'assets/images/smiling green cartoon crocodile@2x.webp')
              : null,
          createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
          title: json['title'] ?? 'Refeição',
          description: json['description'] ?? '',
          kcalLabel: '${json['calories']} kcal',
          timeLabel: json['timeLabel'] ?? '12:00',
          calories: _asRoundedInt(json['calories']),
          protein: _asRoundedInt(json['protein']),
          carbs: _asRoundedInt(json['carbs']),
          fat: _asRoundedInt(json['fat']),
          items: items,
        );
      }).toList();
    }
    return [];
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

  Future<void> saveMeal({
    required FoodMealRecord record,
    required FoodAnalysisResult analysis,
  }) async {
    final uri = Uri.parse('$_baseUrl/meals');
    final uploadedImageUrl = record.imageBytes != null
        ? await SupabaseStorageService.uploadMealPhoto(record.imageBytes!)
        : null;
    final imageUrl = uploadedImageUrl ?? record.imageUrl ?? record.imageAsset;
    final body = {
      'title': record.title,
      'description': record.description,
      'calories': analysis.totals.calories.round(),
      'protein': analysis.totals.protein.round(),
      'carbs': analysis.totals.carbs.round(),
      'fat': analysis.totals.fat.round(),
      'timeLabel': record.timeLabel,
      'imageUrl': imageUrl,
      'analysisItems': analysis.items.map((i) => i.toJson()).toList(),
    };

    final response = await http.post(
      uri,
      headers: _buildHeaders(withJsonContentType: true),
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to save meal');
    }
  }
}
