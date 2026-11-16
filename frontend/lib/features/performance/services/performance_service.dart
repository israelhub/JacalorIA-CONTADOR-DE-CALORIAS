import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../auth/service/auth_service.dart';
import '../helpers/performance_month_helpers.dart';
import '../models/monthly_performance.dart';
import '../models/weight_history.dart';

import '../../../core/config/api_config.dart';

class PerformanceService {
  const PerformanceService();

  static String get _baseUrl => ApiConfig.baseUrl;

  Future<MonthlyPerformance> fetchMonthlyPerformance(DateTime month) async {
    final token = AuthService.globalToken;
    if (token == null || token.isEmpty) {
      throw Exception('Sessão inválida. Faça login novamente.');
    }

    final monthQuery = performanceMonthQuery(month);
    final uri = Uri.parse('$_baseUrl/performance/monthly?month=$monthQuery');

    final response = await http.get(
      uri,
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return MonthlyPerformance.fromJson(body);
    }

    final message = body['message'];
    if (message is String && message.isNotEmpty) {
      throw Exception(message);
    }

    throw Exception('Erro ao carregar desempenho do mês.');
  }

  Future<WeightHistory> fetchWeightHistory({
    String period = '30',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final token = AuthService.globalToken;
    if (token == null || token.isEmpty) {
      throw Exception('Sessão inválida. Faça login novamente.');
    }

    final query = <String, String>{'period': period};
    if (period == 'custom' && startDate != null && endDate != null) {
      query['startDate'] = _toDateText(startDate);
      query['endDate'] = _toDateText(endDate);
    }

    final uri = Uri.parse('$_baseUrl/performance/weight-history')
        .replace(queryParameters: query);

    final response = await http.get(
      uri,
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return WeightHistory.fromJson(body);
    }

    final message = body['message'];
    if (message is String && message.isNotEmpty) {
      throw Exception(message);
    }

    throw Exception('Erro ao carregar histórico de peso.');
  }

  String _toDateText(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
