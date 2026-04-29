import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../auth/service/auth_service.dart';
import '../models/social_group_models.dart';

import '../../../core/config/api_config.dart';

class SocialService {
  const SocialService();

  static String get _baseUrl => ApiConfig.baseUrl;

  Future<List<SocialGroupSummary>> fetchGroups() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/social/groups'),
      headers: _headers(),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return (body['groups'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SocialGroupSummary.fromJson)
          .toList(growable: false);
    }

    throw Exception(_extractMessage(body, 'Erro ao carregar grupos.'));
  }

  Future<SocialGroupDetail> fetchGroup(String groupId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/social/groups/$groupId'),
      headers: _headers(),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return SocialGroupDetail.fromJson(body);
    }

    throw Exception(_extractMessage(body, 'Erro ao carregar o grupo.'));
  }

  Future<SocialGroupDetail> createGroup({
    required String name,
    required String description,
    required String competitionType,
    required String iconKey,
    int durationDays = 7,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/social/groups'),
      headers: _headers(withJsonContentType: true),
      body: jsonEncode({
        'name': name,
        'description': description,
        'competitionType': competitionType,
        'iconKey': iconKey,
        'durationDays': durationDays,
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 201 || response.statusCode == 200) {
      return SocialGroupDetail.fromJson(body);
    }

    throw Exception(_extractMessage(body, 'Erro ao criar grupo.'));
  }

  Future<SocialGroupDetail> updateGroup({
    required String groupId,
    required String name,
    required String description,
    required String competitionType,
    required String iconKey,
    required int durationDays,
  }) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/social/groups/$groupId'),
      headers: _headers(withJsonContentType: true),
      body: jsonEncode({
        'name': name,
        'description': description,
        'competitionType': competitionType,
        'iconKey': iconKey,
        'durationDays': durationDays,
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return SocialGroupDetail.fromJson(body);
    }

    throw Exception(_extractMessage(body, 'Erro ao atualizar grupo.'));
  }

  Map<String, String> _headers({bool withJsonContentType = false}) {
    final token = AuthService.globalToken;
    if (token == null || token.isEmpty) {
      throw Exception('Sessão inválida. Faça login novamente.');
    }

    final headers = <String, String>{'Authorization': 'Bearer $token'};
    if (withJsonContentType) {
      headers['Content-Type'] = 'application/json';
    }

    return headers;
  }

  String _extractMessage(Map<String, dynamic> body, String fallback) {
    final message = body['message'];
    if (message is String && message.isNotEmpty) {
      return message;
    }

    if (message is List && message.isNotEmpty) {
      return message.first.toString();
    }

    return fallback;
  }
}
