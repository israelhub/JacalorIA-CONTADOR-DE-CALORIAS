import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../auth/service/auth_service.dart';
import '../models/missions_overview.dart';

import '../../../core/config/api_config.dart';

class MissionsService {
  const MissionsService();

  static String get _baseUrl => ApiConfig.baseUrl;

  Future<MissionsOverview> fetchMissions() async {
    final token = AuthService.globalToken;
    if (token == null || token.isEmpty) {
      throw Exception('Sessão inválida. Faça login novamente.');
    }

    final uri = Uri.parse('$_baseUrl/missions');

    final response = await http.get(
      uri,
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return MissionsOverview.fromJson(body);
    }

    final message = body['message'];
    if (message is String && message.isNotEmpty) {
      throw Exception(message);
    }

    throw Exception('Erro ao carregar missões.');
  }
}
