import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../auth/service/auth_service.dart';
import '../../../core/config/api_config.dart';
import '../models/food_meal_record.dart';
import '../models/saved_meal_template.dart';

class MealTemplateService {
  const MealTemplateService();

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

  Future<List<SavedMealTemplate>> fetchTemplates() async {
    final uri = Uri.parse('$_baseUrl/meal-templates');
    final response = await http.get(uri, headers: _buildHeaders());

    if (response.statusCode != 200) {
      throw Exception('Não foi possível carregar as refeições salvas');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data
        .whereType<Map<String, dynamic>>()
        .map(SavedMealTemplate.fromJson)
        .toList(growable: false);
  }

  Future<SavedMealTemplate> saveFromMeal(FoodMealRecord record) async {
    final uri = Uri.parse('$_baseUrl/meal-templates');
    final body = {
      'title': record.title,
      'description': record.description,
      'calories': record.calories,
      'protein': record.protein,
      'carbs': record.carbs,
      'fat': record.fat,
      'imageUrl': record.imageUrl ?? record.imageAsset,
      'analysisItems': record.items.map((item) => item.toJson()).toList(),
    };

    final response = await http.post(
      uri,
      headers: _buildHeaders(withJsonContentType: true),
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Não foi possível salvar a refeição');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return SavedMealTemplate.fromJson(decoded);
  }

  Future<void> deleteTemplate({required String templateId}) async {
    final uri = Uri.parse('$_baseUrl/meal-templates/$templateId/delete');
    final response = await http.patch(uri, headers: _buildHeaders());

    if (response.statusCode != 204) {
      throw Exception('Não foi possível remover a refeição salva');
    }
  }
}
