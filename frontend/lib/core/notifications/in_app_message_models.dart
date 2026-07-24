/// Mensagem in-app (lembretes de refeição e avisos cadastrados pelos devs).
class InAppMessage {
  const InAppMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.source,
    this.sourceKey,
    this.readAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  /// Ex.: `meal_reminder`, `catalog`.
  final String source;

  /// Chave estável para deduplicar (ex.: `meal_reminder:breakfast:2026-07-24`).
  final String? sourceKey;

  bool get isUnread => readAt == null;

  InAppMessage copyWith({DateTime? readAt, bool clearReadAt = false}) {
    return InAppMessage(
      id: id,
      title: title,
      body: body,
      createdAt: createdAt,
      source: source,
      sourceKey: sourceKey,
      readAt: clearReadAt ? null : (readAt ?? this.readAt),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'source': source,
      'sourceKey': sourceKey,
    };
  }

  factory InAppMessage.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(Object? value) {
      if (value is! String || value.trim().isEmpty) {
        return null;
      }
      return DateTime.tryParse(value);
    }

    return InAppMessage(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : 'Aviso',
      body: (json['body'] as String?)?.trim() ?? '',
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
      readAt: parseDate(json['readAt']),
      source: (json['source'] as String?)?.trim().isNotEmpty == true
          ? (json['source'] as String).trim()
          : 'catalog',
      sourceKey: (json['sourceKey'] as String?)?.trim().isNotEmpty == true
          ? (json['sourceKey'] as String).trim()
          : null,
    );
  }
}

abstract final class InAppMessageSources {
  static const mealReminder = 'meal_reminder';
  static const catalog = 'catalog';
}
