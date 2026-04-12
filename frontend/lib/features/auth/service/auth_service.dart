import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get _baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }

    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://127.0.0.1:3000/api'
        : 'http://localhost:3000/api';
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
}
