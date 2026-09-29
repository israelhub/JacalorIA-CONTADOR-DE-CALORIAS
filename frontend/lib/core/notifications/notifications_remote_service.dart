import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../../features/auth/service/auth_service.dart';
import 'in_app_message_models.dart';
import 'meal_reminder_models.dart';

/// Configurações de lembretes vindas do backend + carimbo de atualização.
typedef RemoteReminderSettings = ({
  MealReminderSettings settings,
  String updatedAt,
});

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

  /// Retorna as configurações salvas no backend, ou `null` se o usuário
  /// nunca salvou (ou sem sessão/erro de rede).
  Future<RemoteReminderSettings?> fetchReminderSettings() async {
    final token = AuthService.globalToken;
    if (token == null || token.isEmpty) {
      return null;
    }

    final response = await http
        .get(
          Uri.parse('$_baseUrl/notifications/reminder-settings'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      return null;
    }
    return _parseReminderSettings(decoded['settings']);
  }

  /// Salva no backend e retorna o novo `updatedAt`, ou `null` em falha.
  Future<String?> saveReminderSettings(MealReminderSettings settings) async {
    final token = AuthService.globalToken;
    if (token == null || token.isEmpty) {
      return null;
    }

    final response = await http
        .put(
          Uri.parse('$_baseUrl/notifications/reminder-settings'),
          headers: _headers,
          body: jsonEncode(<String, dynamic>{
            'masterEnabled': settings.masterEnabled,
            'reminders': settings.reminders
                .map((item) => item.toJson())
                .toList(growable: false),
          }),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      return null;
    }
    return _parseReminderSettings(decoded['settings'])?.updatedAt;
  }

  RemoteReminderSettings? _parseReminderSettings(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(raw);
    final updatedAt = (map['updatedAt'] ?? '').toString();
    if (updatedAt.isEmpty) {
      return null;
    }

    final rawReminders = map['reminders'];
    final reminders = <MealReminderConfig>[];
    if (rawReminders is List) {
      for (final entry in rawReminders) {
        if (entry is! Map) {
          continue;
        }
        reminders.add(
          MealReminderConfig.fromJson(Map<String, dynamic>.from(entry)),
        );
        if (reminders.length >= MealReminderSettings.maxReminders) {
          break;
        }
      }
    }

    return (
      settings: MealReminderSettings(
        masterEnabled: map['masterEnabled'] is bool
            ? map['masterEnabled'] as bool
            : true,
        reminders: List<MealReminderConfig>.unmodifiable(reminders),
      ),
      updatedAt: updatedAt,
    );
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
