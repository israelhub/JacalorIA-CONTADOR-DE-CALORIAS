import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../../features/auth/service/auth_service.dart';
import 'in_app_message_models.dart';

class NotificationsRemoteService {
  const NotificationsRemoteService();

  static String get _baseUrl => ApiConfig.baseUrl;

  Map<String, String> get _headers {
    final token = AuthService.globalToken;
    return <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<InAppMessage>> fetchInbox() async {
    final token = AuthService.globalToken;
    if (token == null || token.isEmpty) {
      return const <InAppMessage>[];
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/notifications/inbox'),
      headers: _headers,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return const <InAppMessage>[];
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      return const <InAppMessage>[];
    }

    final items = <InAppMessage>[];
    for (final entry in decoded) {
      if (entry is! Map) {
        continue;
      }
      final map = Map<String, dynamic>.from(entry);
      final message = InAppMessage.fromJson(<String, dynamic>{
        'id': map['id'],
        'title': map['title'],
        'body': map['body'],
        'createdAt': map['createdAt'],
        'readAt': map['readAt'],
        'source': map['source'] ?? InAppMessageSources.catalog,
        'sourceKey': map['sourceKey'],
      });
      if (message.id.isEmpty) {
        continue;
      }
      items.add(message);
    }
    return items;
  }

  Future<void> markRead(String id) async {
    final token = AuthService.globalToken;
    if (token == null || token.isEmpty || id.trim().isEmpty) {
      return;
    }
    try {
      await http.post(
        Uri.parse('$_baseUrl/notifications/${Uri.encodeComponent(id)}/read'),
        headers: _headers,
      );
    } catch (_) {
      // best-effort
    }
  }

  Future<void> dismiss(String id) async {
    final token = AuthService.globalToken;
    if (token == null || token.isEmpty || id.trim().isEmpty) {
      return;
    }
    try {
      await http.delete(
        Uri.parse('$_baseUrl/notifications/${Uri.encodeComponent(id)}'),
        headers: _headers,
      );
    } catch (_) {
      // best-effort
    }
  }
}
