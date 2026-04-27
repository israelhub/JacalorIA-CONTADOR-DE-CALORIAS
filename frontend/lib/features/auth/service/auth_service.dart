import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/api_config.dart';

class AuthService {
  static String get _baseUrl => ApiConfig.baseUrl;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    globalToken = prefs.getString('auth_token');
    final userJson = prefs.getString('auth_user');
    if (userJson != null) {
      try {
        globalUser = jsonDecode(userJson) as Map<String, dynamic>;
      } catch (_) {}
    }
  }

  Future<void> signInWithGoogle() async {
    throw UnimplementedError(
      'signInWithGoogle ainda não implementado',
    );
  }

  Future<Map<String, dynamic>> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/register');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'email': email,
            'password': password,
          }),
        )
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () => throw TimeoutException('Timeout ao criar conta'),
        );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 201) {
      return body;
    } else {
      throw Exception(_extractMessage(body, 'Erro ao criar conta'));
    }
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/login');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () => throw TimeoutException('Timeout ao entrar'),
        );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 201) {
      return body;
    } else {
      throw Exception(_extractMessage(body, 'Credenciais inválidas'));
    }
  }

  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/email/verify');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'code': code}),
        )
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () => throw TimeoutException('Timeout ao confirmar email'),
        );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 201) {
      return body;
    } else {
      throw Exception(_extractMessage(body, 'Código inválido'));
    }
  }

  Future<Map<String, dynamic>> resendCode({required String email}) async {
    final uri = Uri.parse('$_baseUrl/auth/email/resend-code');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}),
        )
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () => throw TimeoutException('Timeout ao reenviar código'),
        );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 201) {
      return body;
    } else {
      throw Exception(_extractMessage(body, 'Erro ao reenviar código'));
    }
  }

  static String? globalToken;
  static Map<String, dynamic>? globalUser;

  String _extractMessage(Map<String, dynamic> body, String fallback) {
    final message = body['message'];
    if (message is List && message.isNotEmpty) {
      return message.first.toString();
    }
    if (message is String && message.isNotEmpty) {
      return message;
    }
    return fallback;
  }

  Map<String, String> _getHeaders() {
    final token = _requireToken();

    final headers = <String, String>{'Content-Type': 'application/json'};
    headers['Authorization'] = 'Bearer $token';

    return headers;
  }

  String _requireToken() {
    final token = globalToken;
    if (token == null || token.isEmpty) {
      throw Exception('Sessão inválida. Faça login novamente.');
    }

    return token;
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    final token = _requireToken();
    final uri = Uri.parse('$_baseUrl/auth/profile');
    final headers = <String, String>{'Authorization': 'Bearer $token'};

    final response = await http
        .get(uri, headers: headers)
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () => throw TimeoutException('Timeout ao buscar perfil'),
        );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return body.containsKey('id') ? body : (body['user'] ?? body);
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Sessão inválida. Faça login novamente.');
    } else {
      throw Exception(_extractMessage(body, 'Erro ao buscar perfil'));
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final uri = Uri.parse('$_baseUrl/auth/profile');
    final headers = _getHeaders();

    final response = await http
        .patch(
          uri,
          headers: headers,
          body: jsonEncode(data),
        )
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () => throw TimeoutException('Timeout ao atualizar perfil'),
        );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Sessão inválida. Faça login novamente.');
    }

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(_extractMessage(body, 'Erro ao atualizar perfil'));
    }
  }

  Future<void> signOut() async {
    globalToken = null;
    globalUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
  }
}
