import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../auth/service/auth_service.dart';
import '../../../shared/services/supabase_storage_service.dart';
import '../../food_analysis/helpers/food_review_helpers.dart';
import '../../food_analysis/models/food_meal_record.dart';
import '../../food_analysis/models/food_analysis_result.dart';

import '../../../core/config/api_config.dart';

class MealService {
  const MealService();

  static String get _baseUrl => ApiConfig.baseUrl;
  static final Map<String, String> _mealImageUrlById = <String, String>{};

  static void clearImageUrlCache() {
    _mealImageUrlById.clear();
  }

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

  Future<List<FoodMealRecord>> fetchMeals({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) {
      queryParams['startDate'] = startDate.toUtc().toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toUtc().toIso8601String();
    }

    final uri = Uri.parse('$_baseUrl/meals').replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final response = await http.get(uri, headers: _buildHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return _mergeMealImageUrls(
        data
            .whereType<Map>()
            .map(
              (json) => FoodMealRecord.fromJson(Map<String, dynamic>.from(json)),
            )
            .toList(),
      );
    }
    return [];
  }

  Future<FoodMealRecord> saveMeal({
    required FoodMealRecord record,
    required FoodAnalysisResult analysis,
  }) async {
    final uri = Uri.parse('$_baseUrl/meals');
    final uploadedImageUrl = record.imageBytes != null
        ? await SupabaseStorageService.uploadMealPhoto(record.imageBytes!)
        : null;
    final imageUrl = uploadedImageUrl ?? record.imageUrl ?? record.imageAsset;
    final body = <String, dynamic>{
      'title': record.title,
      'description': record.description,
      'calories': analysis.totals.calories.round(),
      'protein': analysis.totals.protein.round(),
      'carbs': analysis.totals.carbs.round(),
      'fat': analysis.totals.fat.round(),
      'timeLabel': record.timeLabel,
      'mealType': record.mealType.apiValue,
      'imageUrl': imageUrl,
      'analysisItems': analysis.items.map((i) => i.toJson()).toList(),
      if (record.createdAt != null)
        'createdAt': record.createdAt!.toUtc().toIso8601String(),
    };

    final response = await http.post(
      uri,
      headers: _buildHeaders(withJsonContentType: true),
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to save meal');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return FoodMealRecord.fromJson(decoded);
  }

  Future<FoodMealRecord> updateMeal({
    required String mealId,
    required FoodMealRecord record,
    required FoodAnalysisResult analysis,
  }) async {
    final uri = Uri.parse('$_baseUrl/meals/$mealId');
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
      'mealType': record.mealType.apiValue,
      'imageUrl': imageUrl,
      'analysisItems': analysis.items.map((i) => i.toJson()).toList(),
    };

    final response = await http.patch(
      uri,
      headers: _buildHeaders(withJsonContentType: true),
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update meal');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return FoodMealRecord.fromJson(decoded);
  }

  Future<void> softDeleteMeal({required String mealId}) async {
    final uri = Uri.parse('$_baseUrl/meals/$mealId/delete');
    final response = await http.patch(uri, headers: _buildHeaders());

    if (response.statusCode != 204) {
      throw Exception('Failed to delete meal');
    }
  }

  List<FoodMealRecord> _mergeMealImageUrls(List<FoodMealRecord> meals) {
    return meals.map((meal) {
      final id = meal.id?.trim() ?? '';
      final url = meal.imageUrl?.trim();
      if (id.isNotEmpty && url != null && url.isNotEmpty) {
        _mealImageUrlById[id] = url;
      }
      if (url != null && url.isNotEmpty) {
        return meal;
      }
      if (id.isEmpty) {
        return meal;
      }
      final cached = _mealImageUrlById[id];
      if (cached == null || cached.isEmpty) {
        return meal;
      }
      return meal.copyWith(imageUrl: cached);
    }).toList(growable: false);
  }
}
