import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../auth/service/auth_service.dart';

enum SupportSubjectType {
  bug('bug'),
  suggestion('suggestion');

  const SupportSubjectType(this.apiValue);

  final String apiValue;

  String get label {
    switch (this) {
      case SupportSubjectType.bug:
        return 'Bug';
      case SupportSubjectType.suggestion:
        return 'Sugestão';
    }
  }
}

class SupportService {
  const SupportService();

  static String get _baseUrl => ApiConfig.baseUrl;

  Future<void> sendMessage({
    required SupportSubjectType subjectType,
    required String description,
    String? email,
  }) async {
    final token = AuthService.globalToken;
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final body = <String, dynamic>{
      'subjectType': subjectType.apiValue,
      'description': description.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/support/messages'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'];
      if (message is String && message.isNotEmpty) {
        throw Exception(message);
      }
      if (message is List && message.isNotEmpty) {
        throw Exception(message.first.toString());
      }
    }

    throw Exception('Não foi possível enviar sua mensagem. Tente novamente.');
  }
}
