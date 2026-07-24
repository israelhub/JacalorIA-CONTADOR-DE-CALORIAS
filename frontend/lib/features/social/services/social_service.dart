import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../auth/service/auth_service.dart';
import '../models/social_group_models.dart';

class SocialService {
  const SocialService();

  static String get _baseUrl => ApiConfig.baseUrl;

  // Sementes de stale-while-revalidate: guardam a última resposta conhecida
  // por chave para as telas pintarem na hora e revalidarem em segundo plano.
  // Sem TTL — as telas sempre disparam a revalidação silenciosa.
  static final Map<String, SocialGroupDetail> _groupSeed =
      <String, SocialGroupDetail>{};
  static final Map<String, SocialFriendProfile> _friendProfileSeed =
      <String, SocialFriendProfile>{};
  static SocialFriendsData? _friendsSeed;

  static SocialGroupDetail? cachedGroup(String groupId) =>
      _groupSeed[groupId.trim()];

  static SocialFriendProfile? cachedFriendProfile(
    String friendUserId, {
    String? groupId,
    String? viaUserId,
  }) =>
      _friendProfileSeed[_friendProfileKey(friendUserId, groupId, viaUserId)];

  static SocialFriendsData? get cachedFriends => _friendsSeed;

  static String _friendProfileKey(
    String friendUserId,
    String? groupId,
    String? viaUserId,
  ) =>
      '${friendUserId.trim()}|${groupId?.trim() ?? ''}|${viaUserId?.trim() ?? ''}';

  static void clearSeedCache() {
    _groupSeed.clear();
    _friendProfileSeed.clear();
    _friendsSeed = null;
  }

  Future<List<SocialGroupSummary>> fetchGroups() async {
    final response = await http.get(Uri.parse('$_baseUrl/social/groups'), headers: _headers());
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return (body['groups'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SocialGroupSummary.fromJson)
          .toList(growable: false);
    }
    throw Exception(_extractMessage(body, 'Erro ao carregar grupos.'));
  }

  Future<SocialFriendsData> fetchFriends() async {
    final response = await http.get(Uri.parse('$_baseUrl/social/friends'), headers: _headers());
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      final data = _parseFriendsData(body);
      _friendsSeed = data;
      return data;
    }
    throw Exception(_extractMessage(body, 'Erro ao carregar amigos.'));
  }

  Future<SocialFriendsData> addFriendByEmail(String email) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/social/friends/by-email'),
      headers: _headers(withJsonContentType: true),
      body: jsonEncode({'email': email.trim()}),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _parseFriendsData(body);
    }
    throw Exception(_extractMessage(body, 'Erro ao enviar solicitação de amizade.'));
  }

  Future<SocialFriendsData> addFriendByLinkCode(String inviteCode) async {
    final response = await http.post(Uri.parse('$_baseUrl/social/friends/by-link/${inviteCode.trim()}'), headers: _headers());
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _parseFriendsData(body);
    }
    throw Exception(_extractMessage(body, 'Erro ao enviar solicitação por link.'));
  }

  Future<SocialFriendsData> addFriendById(String friendUserId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/social/friends/by-id/${friendUserId.trim()}'),
      headers: _headers(),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _parseFriendsData(body);
    }
    throw Exception(_extractMessage(body, 'Erro ao enviar solicitação por ID.'));
  }

  Future<SocialFriendsData> acceptFriendRequest(String requestId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/social/friends/requests/${requestId.trim()}/accept'),
      headers: _headers(),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _parseFriendsData(body);
    }
    throw Exception(_extractMessage(body, 'Erro ao aceitar solicitação.'));
  }

  Future<SocialFriendsData> rejectFriendRequest(String requestId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/social/friends/requests/${requestId.trim()}/reject'),
      headers: _headers(),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _parseFriendsData(body);
    }
    throw Exception(_extractMessage(body, 'Erro ao recusar solicitação.'));
  }

  Future<SocialFriendProfile> fetchFriendProfile(
    String friendUserId, {
    String? groupId,
    String? viaUserId,
  }) async {
    final normalizedGroupId = groupId?.trim();
    final normalizedViaUserId = viaUserId?.trim();
    final queryParameters = <String, String>{};
    if (normalizedGroupId != null && normalizedGroupId.isNotEmpty) {
      queryParameters['groupId'] = normalizedGroupId;
    }
    if (normalizedViaUserId != null && normalizedViaUserId.isNotEmpty) {
      queryParameters['viaUserId'] = normalizedViaUserId;
    }
    final uri = Uri.parse(
      '$_baseUrl/social/friends/${friendUserId.trim()}/profile',
    ).replace(queryParameters: queryParameters.isEmpty ? null : queryParameters);
    final response = await http.get(uri, headers: _headers());
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      final profile = SocialFriendProfile.fromJson(body);
      _friendProfileSeed[_friendProfileKey(
        friendUserId,
        normalizedGroupId,
        normalizedViaUserId,
      )] = profile;
      return profile;
    }
      throw Exception(_extractMessage(body, 'Erro ao carregar perfil.'));
  }

  Future<List<SocialFriend>> fetchUserFriends(
    String userId, {
    String? groupId,
    String? viaUserId,
  }) async {
    final normalizedGroupId = groupId?.trim();
    final normalizedViaUserId = viaUserId?.trim();
    final queryParameters = <String, String>{};
    if (normalizedGroupId != null && normalizedGroupId.isNotEmpty) {
      queryParameters['groupId'] = normalizedGroupId;
    }
    if (normalizedViaUserId != null && normalizedViaUserId.isNotEmpty) {
      queryParameters['viaUserId'] = normalizedViaUserId;
    }
    final uri = Uri.parse(
      '$_baseUrl/social/friends/${userId.trim()}/list',
    ).replace(queryParameters: queryParameters.isEmpty ? null : queryParameters);
    final response = await http.get(uri, headers: _headers());
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return (body['friends'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SocialFriend.fromJson)
          .toList(growable: false);
    }
    throw Exception(_extractMessage(body, 'Erro ao carregar amigos.'));
  }

  Future<SocialFriendsData> removeFriend(String friendUserId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/social/friends/${friendUserId.trim()}/remove'),
      headers: _headers(),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _parseFriendsData(body);
    }
    throw Exception(_extractMessage(body, 'Erro ao desfazer amizade.'));
  }

  Future<List<SocialUserSearchResult>> searchUsers(String query) async {
    final uri = Uri.parse('$_baseUrl/social/users/search').replace(
      queryParameters: {'q': query.trim()},
    );
    final response = await http.get(uri, headers: _headers());
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return (body['users'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SocialUserSearchResult.fromJson)
          .toList(growable: false);
    }
    throw Exception(_extractMessage(body, 'Erro ao buscar usuários.'));
  }

  Future<SocialGroupDetail> joinGroupByInviteCode(String inviteCode) async {
    final response = await http.post(Uri.parse('$_baseUrl/social/groups/join/${inviteCode.trim()}'), headers: _headers());
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) {
      final detail = SocialGroupDetail.fromJson(body);
      _seedGroup(detail);
      return detail;
    }
    throw Exception(_extractMessage(body, 'Erro ao entrar no grupo.'));
  }

  Future<List<SocialGroupSummary>> fetchPublicGroups({
    String query = '',
    int? durationDays,
    String? competitionType,
  }) async {
    final params = <String, String>{};
    if (query.trim().isNotEmpty) params['q'] = query.trim();
    if (durationDays != null) params['durationDays'] = durationDays.toString();
    if (competitionType != null && competitionType.trim().isNotEmpty) {
      params['competitionType'] = competitionType.trim();
    }
    final uri = Uri.parse('$_baseUrl/social/groups/public').replace(queryParameters: params.isEmpty ? null : params);
    final response = await http.get(uri, headers: _headers());
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return (body['groups'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SocialGroupSummary.fromJson)
          .toList(growable: false);
    }
    throw Exception(_extractMessage(body, 'Erro ao carregar grupos públicos.'));
  }

  Future<SocialGroupDetail> joinPublicGroup(String groupId) async {
    final response = await http.post(Uri.parse('$_baseUrl/social/groups/public/${groupId.trim()}/join'), headers: _headers());
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) {
      final detail = SocialGroupDetail.fromJson(body);
      _seedGroup(detail);
      return detail;
    }
    throw Exception(_extractMessage(body, 'Erro ao entrar no grupo público.'));
  }

  Future<SocialGroupDetail> fetchGroup(String groupId) async {
    final response = await http.get(Uri.parse('$_baseUrl/social/groups/$groupId'), headers: _headers());
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      final detail = SocialGroupDetail.fromJson(body);
      _groupSeed[groupId.trim()] = detail;
      return detail;
    }
    throw Exception(_extractMessage(body, 'Erro ao carregar o grupo.'));
  }

  Future<SocialMemberDailyMeals> fetchGroupMemberDailyMeals({
    required String groupId,
    required String memberUserId,
    String? date,
  }) async {
    final queryParameters = <String, String>{};
    final normalizedDate = date?.trim();
    if (normalizedDate != null && normalizedDate.isNotEmpty) {
      queryParameters['date'] = normalizedDate;
    }
    final uri = Uri.parse(
      '$_baseUrl/social/groups/${groupId.trim()}/members/${memberUserId.trim()}/daily-meals',
    ).replace(queryParameters: queryParameters.isEmpty ? null : queryParameters);
    final response = await http.get(uri, headers: _headers());
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return SocialMemberDailyMeals.fromJson(body);
    }
    throw Exception(_extractMessage(body, 'Erro ao carregar refeições do membro.'));
  }

  Future<void> leaveGroup(String groupId) async {
    final response = await http.post(Uri.parse('$_baseUrl/social/groups/${groupId.trim()}/leave'), headers: _headers());
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) {
      _groupSeed.remove(groupId.trim());
      return;
    }
    throw Exception(_extractMessage(body, 'Erro ao sair do grupo.'));
  }

  Future<void> deleteGroup(String groupId) async {
    final response = await http.delete(Uri.parse('$_baseUrl/social/groups/${groupId.trim()}'), headers: _headers());
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) {
      _groupSeed.remove(groupId.trim());
      return;
    }
    throw Exception(_extractMessage(body, 'Erro ao excluir o grupo.'));
  }

  Future<SocialGroupDetail> addGroupMembers({
    required String groupId,
    required List<String> memberUserIds,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/social/groups/${groupId.trim()}/members'),
      headers: _headers(withJsonContentType: true),
      body: jsonEncode({'memberUserIds': memberUserIds}),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) {
      final detail = SocialGroupDetail.fromJson(body);
      _seedGroup(detail);
      return detail;
    }
    throw Exception(_extractMessage(body, 'Erro ao convidar amigos para o grupo.'));
  }

  Future<SocialGroupDetail> removeGroupMember({
    required String groupId,
    required String memberUserId,
  }) async {
    final response = await http.post(
      Uri.parse(
        '$_baseUrl/social/groups/${groupId.trim()}/members/${memberUserId.trim()}/remove',
      ),
      headers: _headers(),
    );
    final body = _decodeJsonMap(
      response.body,
      fallbackError: 'Erro ao excluir membro do grupo.',
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final detail = SocialGroupDetail.fromJson(body);
      _seedGroup(detail);
      return detail;
    }
    throw Exception(_extractMessage(body, 'Erro ao excluir membro do grupo.'));
  }

  Future<SocialGroupDetail> createGroup({
    required String name,
    required String description,
    required String competitionType,
    required String iconKey,
    int durationDays = 7,
    List<String> memberUserIds = const [],
    bool isPublic = false,
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
        'memberUserIds': memberUserIds,
        'isPublic': isPublic,
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 201 || response.statusCode == 200) {
      final detail = SocialGroupDetail.fromJson(body);
      _seedGroup(detail);
      return detail;
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
    required bool isPublic,
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
        'isPublic': isPublic,
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      final detail = SocialGroupDetail.fromJson(body);
      _seedGroup(detail);
      return detail;
    }
    throw Exception(_extractMessage(body, 'Erro ao atualizar grupo.'));
  }

  Map<String, String> _headers({bool withJsonContentType = false}) {
    final token = AuthService.globalToken;
    if (token == null || token.isEmpty) throw Exception('Sessão inválida. Faça login novamente.');

    final headers = <String, String>{'Authorization': 'Bearer $token'};
    if (withJsonContentType) headers['Content-Type'] = 'application/json';
    return headers;
  }

  Map<String, dynamic> _decodeJsonMap(String rawBody, {required String fallbackError}) {
    final trimmed = rawBody.trimLeft();
    if (trimmed.isEmpty) {
      throw Exception(fallbackError);
    }
    if (trimmed.startsWith('<')) {
      throw Exception(
        'A API não reconheceu esta ação. Reinicie o backend local ou publique a versão mais recente.',
      );
    }
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw Exception(fallbackError);
    } on FormatException {
      throw Exception(fallbackError);
    }
  }

  String _extractMessage(Map<String, dynamic> body, String fallback) {
    final message = body['message'];
    if (message is String && message.isNotEmpty) return message;
    if (message is List && message.isNotEmpty) return message.first.toString();
    return fallback;
  }

  void _seedGroup(SocialGroupDetail detail) {
    final id = detail.group.id.trim();
    if (id.isNotEmpty) {
      _groupSeed[id] = detail;
    }
  }

  SocialFriendsData _parseFriendsData(Map<String, dynamic> body) {
    _friendsSeed = SocialFriendsData(
      friends: (body['friends'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SocialFriend.fromJson)
          .toList(growable: false),
      inviteCode: body['inviteCode']?.toString() ?? '',
      pendingRequests: (body['pendingRequests'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SocialFriendRequest.fromJson)
          .toList(growable: false),
    );
    return _friendsSeed!;
  }
}
