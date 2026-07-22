import '../helpers/social_model_parsers.dart';

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
  return false;
}

class SocialRankingEntry {
  const SocialRankingEntry({
    required this.id,
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.avatarFrameId,
    required this.points,
    required this.streakDays,
    required this.isCurrentUser,
    required this.isLeader,
    required this.position,
    required this.subtitle,
  });

  final String id;
  final String userId;
  final String name;
  final String? avatarUrl;
  final String? avatarFrameId;
  final num points;
  final int streakDays;
  final bool isCurrentUser;
  final bool isLeader;
  final int position;
  final String subtitle;

  factory SocialRankingEntry.fromJson(Map<String, dynamic> json) {
    return SocialRankingEntry(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      avatarFrameId: json['avatarFrameId']?.toString(),
      points: socialToNum(json['points']),
      streakDays: socialToInt(json['streakDays']),
      isCurrentUser: _toBool(json['isCurrentUser']),
      isLeader: _toBool(json['isLeader']),
      position: socialToInt(json['position']),
      subtitle: json['subtitle']?.toString() ?? '',
    );
  }
}
