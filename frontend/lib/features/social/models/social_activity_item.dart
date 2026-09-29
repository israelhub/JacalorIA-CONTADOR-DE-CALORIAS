class SocialActivityItem {
  const SocialActivityItem({required this.id, required this.message, required this.activityType, required this.createdAt, required this.metadata});

  final String id;
  final String message;
  final String activityType;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  factory SocialActivityItem.fromJson(Map<String, dynamic> json) {
    return SocialActivityItem(
      id: json['id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      activityType: json['activityType']?.toString() ?? 'activity',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      metadata: json['metadata'] is Map<String, dynamic> ? json['metadata'] as Map<String, dynamic> : null,
    );
  }
}
