import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/api_config.dart';

class AuthService {
  static const Duration _apiTimeout = Duration(seconds: 45);

  static String get _baseUrl => ApiConfig.baseUrl;
  static const String _googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '618330390967-emagf9ea3j4l5kaeroi2s1bs527ugc0i.apps.googleusercontent.com',
  );
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'openid'],
    // Sem google-services.json, Android deve usar o Web Client ID como serverClientId.
    clientId: (kIsWeb || defaultTargetPlatform == TargetPlatform.android)
        ? _googleWebClientId
        : null,
  );

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

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      if (kIsWeb && _googleWebClientId.isEmpty) {
        throw Exception(
          'GOOGLE_WEB_CLIENT_ID nao configurado. Rode com --dart-define=GOOGLE_WEB_CLIENT_ID=<seu_client_id_web>',
        );
      }

      final silentAccount = await _googleSignIn.signInSilently();
      final account = silentAccount ?? await _googleSignIn.signIn();
      if (account == null) {
        throw Exception('Login com Google cancelado.');
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;
      if ((idToken == null || idToken.isEmpty) &&
          (accessToken == null || accessToken.isEmpty)) {
        throw Exception('Nao foi possivel obter credenciais do Google.');
      }

      final uri = Uri.parse('$_baseUrl/auth/google');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              if (idToken != null && idToken.isNotEmpty) 'idToken': idToken,
              if (accessToken != null && accessToken.isNotEmpty)
                'accessToken': accessToken,
            }),
          )
          .timeout(
            _apiTimeout,
            onTimeout: () => throw TimeoutException('Timeout no login Google'),
          );

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (kDebugMode) {
        debugPrint(
          '[GoogleSignIn] /auth/google status=${response.statusCode} body=$body',
        );
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        return body;
      } else {
        throw Exception(
          _friendlyGoogleSignInMessage(
            _extractMessage(body, 'Falha no login com Google'),
          ),
        );
      }
    } catch (e) {
      throw Exception(_friendlyGoogleSignInMessage(e.toString()));
    }
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
          _apiTimeout,
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
          _apiTimeout,
          onTimeout: () => throw TimeoutException('Timeout ao entrar'),
        );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 201) {
      return body;
    } else {
      throw Exception(_extractMessage(body, 'Credenciais invalidas'));
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
          _apiTimeout,
          onTimeout: () => throw TimeoutException('Timeout ao confirmar email'),
        );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 201) {
      return body;
    } else {
      throw Exception(_extractMessage(body, 'Codigo invalido'));
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
          _apiTimeout,
          onTimeout: () => throw TimeoutException('Timeout ao reenviar codigo'),
        );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 201) {
      return body;
    } else {
      throw Exception(_extractMessage(body, 'Erro ao reenviar codigo'));
    }
  }

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    final uri = Uri.parse('$_baseUrl/auth/password/forgot');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}),
        )
        .timeout(
          _apiTimeout,
          onTimeout: () => throw TimeoutException('Timeout ao solicitar reset'),
        );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 201 || response.statusCode == 200) {
      return body;
    } else {
      throw Exception(_extractMessage(body, 'Erro ao solicitar reset'));
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/password/reset');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'code': code,
            'newPassword': newPassword,
          }),
        )
        .timeout(
          _apiTimeout,
          onTimeout: () => throw TimeoutException('Timeout ao redefinir senha'),
        );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 201 || response.statusCode == 200) {
      return body;
    } else {
      throw Exception(_extractMessage(body, 'Erro ao redefinir senha'));
    }
  }

  Future<Map<String, dynamic>> validateResetCode({
    required String email,
    required String code,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/password/validate-code');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'code': code}),
        )
        .timeout(
          _apiTimeout,
          onTimeout: () => throw TimeoutException('Timeout ao validar codigo'),
        );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 201 || response.statusCode == 200) {
      return body;
    } else {
      throw Exception(_extractMessage(body, 'Codigo invalido ou expirado'));
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

  String _friendlyGoogleSignInMessage(String raw) {
    final message = raw.replaceFirst('Exception: ', '').trim();
    final lower = message.toLowerCase();

    if (lower.contains('people api has not been used') ||
        lower.contains('service_disabled') ||
        lower.contains('permission_denied') ||
        lower.contains('people.googleapis.com')) {
      return 'Login Google bloqueado na configuracao do projeto. Ative a People API no Google Cloud e tente novamente.';
    }

    if (lower.contains('google_web_client_id nao configurado')) {
      return 'Login Google indisponivel no momento. Contate o suporte.';
    }

    if (lower.contains('cancelado')) {
      return 'Login com Google cancelado.';
    }

    if (lower.contains('timeout')) {
      return 'Conexao com Google indisponivel. Verifique sua internet e tente novamente.';
    }

    if (lower.contains('access token google invalido')) {
      return 'Token Google expirado ou invalido. Tente entrar novamente.';
    }

    if (lower.contains('access token google ausente')) {
      return 'Nao foi possivel obter token do Google. Tente novamente.';
    }

    if (lower.contains('apiexception: 10') ||
        lower.contains('api10') ||
        lower.contains('sign_in_failed')) {
      return 'Falha na configuracao do Google Login no Android (ApiException 10). Verifique package name, SHA-1/SHA-256 e OAuth Client ID.';
    }

    if (lower.contains('conta google sem email valido') ||
        lower.contains('email do google nao verificado')) {
      return 'Sua conta Google precisa ter email valido e verificado.';
    }

    if (message.isNotEmpty) {
      return message;
    }

    return 'Nao foi possivel entrar com Google. Tente novamente.';
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
      throw Exception('Sessao invalida. Faca login novamente.');
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
          _apiTimeout,
          onTimeout: () => throw TimeoutException('Timeout ao buscar perfil'),
        );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return body.containsKey('id') ? body : (body['user'] ?? body);
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Sessao invalida. Faca login novamente.');
    } else {
      throw Exception(_extractMessage(body, 'Erro ao buscar perfil'));
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final uri = Uri.parse('$_baseUrl/auth/profile');
    final headers = _getHeaders();

    final response = await http
        .patch(uri, headers: headers, body: jsonEncode(data))
        .timeout(
          _apiTimeout,
          onTimeout: () =>
              throw TimeoutException('Timeout ao atualizar perfil'),
        );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Sessao invalida. Faca login novamente.');
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
