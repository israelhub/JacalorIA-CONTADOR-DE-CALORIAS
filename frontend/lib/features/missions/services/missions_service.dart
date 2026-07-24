import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../auth/service/auth_service.dart';
import '../models/missions_overview.dart';

import '../../../core/config/api_config.dart';

class MissionsService {
  const MissionsService();

  static String get _baseUrl => ApiConfig.baseUrl;

  // Stale-while-revalidate: a loja abre na hora com o último catálogo e
  // revalida em segundo plano.
  static Map<String, dynamic>? _storeCatalogCache;
  static DateTime? _storeCatalogFetchedAt;
  static const Duration _storeCatalogTtl = Duration(minutes: 10);

  static Map<String, dynamic>? get cachedStoreCatalog {
    final fetchedAt = _storeCatalogFetchedAt;
    if (_storeCatalogCache == null || fetchedAt == null) {
      return null;
    }
    if (DateTime.now().difference(fetchedAt) > _storeCatalogTtl) {
      return null;
    }
    return _storeCatalogCache;
  }

  static void invalidateStoreCatalogCache() {
    _storeCatalogCache = null;
    _storeCatalogFetchedAt = null;
  }

  Future<Map<String, dynamic>> fetchStoreCatalog() async {
    // Real route first: on jacaloria.online, CloudFront can turn unknown /api
    // 404s into HTML 200 (SPA fallback), which breaks path fallbacks.
    final body = await _getJsonWithFallback(const <String>[
      '/missions/store',
      '/missions/store/catalog',
      '/missions/catalog',
    ], fallbackError: 'Erro ao carregar catálogo da loja.');
    _storeCatalogCache = body;
    _storeCatalogFetchedAt = DateTime.now();
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
      '/missions/wallet/gold-statement',
      '/missions/gold-statement',
      '/missions/store/gold-statement',
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
      final body = _tryDecodeJsonObject(response);
      if (body == null) {
        // HTML SPA fallback or non-JSON payload — try the next path.
        lastError = fallbackError;
        continue;
      }
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

      final decoded = _tryDecodeJsonObject(response);
      if (decoded == null) {
        lastError = fallbackError;
        continue;
      }
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

  Map<String, dynamic>? _tryDecodeJsonObject(http.Response response) {
    final raw = response.body.trim();
    if (raw.isEmpty) {
      return <String, dynamic>{};
    }
    // CloudFront SPA fallback may return index.html with status 200.
    if (raw.startsWith('<!') || raw.startsWith('<html')) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String? _extractError(Map<String, dynamic> body) {
    final message = body['message'] ?? body['error'];
    if (message is String && message.isNotEmpty) {
      return message;
    }
    if (message is List) {
      return message
          .map((value) => value.toString())
          .where((value) => value.isNotEmpty)
          .join(', ');
    }
    return null;
  }
}
