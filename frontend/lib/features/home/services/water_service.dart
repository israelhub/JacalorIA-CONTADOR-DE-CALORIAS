import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../auth/service/auth_service.dart';
import '../helpers/home_water_helpers.dart';
import '../models/home_water_models.dart';

class WaterService {
  const WaterService();

  static String get _baseUrl => ApiConfig.baseUrl;

  Future<WaterOverview> fetchWater({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final uri = Uri.parse('$_baseUrl/water').replace(
      queryParameters: <String, String>{
        'startDate': homeDateQuery(startDate),
        'endDate': homeDateQuery(endDate),
      },
    );
    final response = await http.get(uri, headers: _headers());
    return WaterOverview.fromJson(_decodeMap(response, 'carregar a água'));
  }

  Future<({int goalMl, WaterDayEntry day})> addWater({
    required int milliliters,
    required DateTime recordedAt,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/water'),
      headers: _headers(json: true),
      body: jsonEncode(<String, Object>{
        'milliliters': milliliters,
        'recordedAt': homeDateQuery(recordedAt),
      }),
    );
    final decoded = _decodeMap(response, 'adicionar água');
    final dayJson = decoded['day'];
    if (dayJson is! Map<String, dynamic>) {
      throw Exception('Resposta inválida ao adicionar água.');
    }
    return (
      goalMl: decoded['goalMl'] is num
          ? (decoded['goalMl'] as num).round()
          : defaultDailyWaterGoalMl,
      day: WaterDayEntry.fromJson(dayJson),
    );
  }

  Map<String, String> _headers({bool json = false}) {
    final token = AuthService.globalToken;
    if (token == null || token.isEmpty) {
      throw Exception('Sessão inválida. Faça login novamente.');
    }

    return <String, String>{
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  Map<String, dynamic> _decodeMap(http.Response response, String action) {
    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return <String, dynamic>{};
      }
      throw Exception('Não foi possível $action.');
    }

    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw Exception('Resposta inválida ao $action.');
    }

    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'];
      if (message is String && message.isNotEmpty) {
        throw Exception(message);
      }
    }

    throw Exception('Não foi possível $action.');
  }
}
