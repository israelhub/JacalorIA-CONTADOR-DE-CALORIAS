import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../auth/service/auth_service.dart';
import '../models/social_group_models.dart';

class SocialService {
  const SocialService();

  static String get _baseUrl => ApiConfig.baseUrl;

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
      return _parseFriendsData(body);
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

  Future<SocialFriendProfile> fetchFriendProfile(String friendUserId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/social/friends/${friendUserId.trim()}/profile'),
      headers: _headers(),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return SocialFriendProfile.fromJson(body);
    }
      throw Exception(_extractMessage(body, 'Erro ao carregar perfil.'));
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
      return SocialGroupDetail.fromJson(body);
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
      return SocialGroupDetail.fromJson(body);
    }
    throw Exception(_extractMessage(body, 'Erro ao entrar no grupo público.'));
  }

  Future<SocialGroupDetail> fetchGroup(String groupId) async {
    final response = await http.get(Uri.parse('$_baseUrl/social/groups/$groupId'), headers: _headers());
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return SocialGroupDetail.fromJson(body);
    }
    throw Exception(_extractMessage(body, 'Erro ao carregar o grupo.'));
  }

  Future<void> leaveGroup(String groupId) async {
    final response = await http.post(Uri.parse('$_baseUrl/social/groups/${groupId.trim()}/leave'), headers: _headers());
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }
    throw Exception(_extractMessage(body, 'Erro ao sair do grupo.'));
  }

  Future<void> deleteGroup(String groupId) async {
    final response = await http.delete(Uri.parse('$_baseUrl/social/groups/${groupId.trim()}'), headers: _headers());
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) {
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
      return SocialGroupDetail.fromJson(body);
    }
    throw Exception(_extractMessage(body, 'Erro ao convidar amigos para o grupo.'));
  }

  Future<SocialGroupDetail> removeGroupMember({
    required String groupId,
    required String memberUserId,
  }) async {
    final response = await http.delete(
      Uri.parse(
        '$_baseUrl/social/groups/${groupId.trim()}/members/${memberUserId.trim()}',
      ),
      headers: _headers(),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) {
      return SocialGroupDetail.fromJson(body);
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
      return SocialGroupDetail.fromJson(body);
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

  String _extractMessage(Map<String, dynamic> body, String fallback) {
    final message = body['message'];
    if (message is String && message.isNotEmpty) return message;
    if (message is List && message.isNotEmpty) return message.first.toString();
    return fallback;
  }

  SocialFriendsData _parseFriendsData(Map<String, dynamic> body) {
    return SocialFriendsData(
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
  }
}
