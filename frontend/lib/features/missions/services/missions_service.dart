import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../auth/service/auth_service.dart';
import '../models/missions_overview.dart';

import '../../../core/config/api_config.dart';

class MissionsService {
  const MissionsService();

  static String get _baseUrl => ApiConfig.baseUrl;

  Future<Map<String, dynamic>> fetchStoreCatalog() async {
    final body = await _getJsonWithFallback(const <String>[
      '/missions/store/catalog',
      '/missions/store',
      '/missions/catalog',
    ], fallbackError: 'Erro ao carregar catálogo da loja.');
    return body;
  }

  Future<MissionsOverview> fetchMissions() async {
    final token = AuthService.globalToken;
    if (token == null || token.isEmpty) {
      throw Exception('Sessão inválida. Faça login novamente.');
    }

    final uri = Uri.parse('$_baseUrl/missions');

    final response = await http.get(
      uri,
      headers: <String, String>{'Authorization': 'Bearer $token'},
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

  Future<Map<String, dynamic>> purchaseAvatarFrame(String frameId) async {
    return _postJsonWithFallback(
      const <String>[
        '/missions/store/avatar-frames/purchase',
        '/missions/store/frames/purchase',
      ],
      body: <String, dynamic>{'frameId': frameId},
      fallbackError: 'Erro ao comprar moldura.',
    );
  }

  Future<Map<String, dynamic>> purchaseAvatarBackground(String backgroundId) {
    return _postJsonWithFallback(
      const <String>[
        '/missions/store/avatar-backgrounds/purchase',
        '/missions/store/backgrounds/purchase',
      ],
      body: <String, dynamic>{'backgroundId': backgroundId},
      fallbackError: 'Erro ao comprar fundo.',
    );
  }

  Future<Map<String, dynamic>> purchaseBlocker({
    required String blockerId,
    int quantity = 1,
  }) {
    return _postJsonWithFallback(
      const <String>[
        '/missions/store/offensive-blockers/purchase',
        '/missions/store/blockers/purchase',
        '/missions/store/profile-blockers/purchase',
      ],
      body: <String, dynamic>{'blockerId': blockerId, 'quantity': quantity},
      fallbackError: 'Erro ao comprar bloqueador.',
    );
  }

  Future<List<Map<String, dynamic>>> fetchGoldStatement() async {
    final body = await _getJsonWithFallback(const <String>[
      '/missions/gold-statement',
      '/missions/store/gold-statement',
      '/missions/wallet/gold-statement',
      '/missions/transactions/gold',
    ], fallbackError: 'Erro ao carregar extrato de ouro.');

    final rawList =
        body['transactions'] ??
        body['entries'] ??
        body['items'] ??
        body['statement'] ??
        body['data'] ??
        body['goldStatement'];
    if (rawList is! List) {
      return const <Map<String, dynamic>>[];
    }

    return rawList.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  Future<Map<String, dynamic>> _getJsonWithFallback(
    List<String> paths, {
    required String fallbackError,
  }) async {
    final token = _requireToken();
    Object? lastError;

    for (final path in paths) {
      final uri = Uri.parse('$_baseUrl$path');
      final response = await http.get(
        uri,
        headers: <String, String>{'Authorization': 'Bearer $token'},
      );
      final body = _decodeBody(response);
      if (response.statusCode == 200) {
        return body;
      }
      lastError = _extractError(body);
      if (response.statusCode != 404) {
        break;
      }
    }

    if (lastError is String && lastError.isNotEmpty) {
      throw Exception(lastError);
    }
    throw Exception(fallbackError);
  }

  Future<Map<String, dynamic>> _postJsonWithFallback(
    List<String> paths, {
    required Map<String, dynamic> body,
    required String fallbackError,
  }) async {
    final token = _requireToken();
    Object? lastError;

    for (final path in paths) {
      final uri = Uri.parse('$_baseUrl$path');
      final response = await http.post(
        uri,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final decoded = _decodeBody(response);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return decoded;
      }
      lastError = _extractError(decoded);
      if (response.statusCode != 404) {
        break;
      }
    }

    if (lastError is String && lastError.isNotEmpty) {
      throw Exception(lastError);
    }
    throw Exception(fallbackError);
  }

  String _requireToken() {
    final token = AuthService.globalToken;
    if (token == null || token.isEmpty) {
      throw Exception('Sessão inválida. Faça login novamente.');
    }
    return token;
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{};
  }

  String? _extractError(Map<String, dynamic> body) {
    final message = body['message'] ?? body['error'];
    if (message is String && message.isNotEmpty) {
      return message;
    }
    return null;
  }
}
