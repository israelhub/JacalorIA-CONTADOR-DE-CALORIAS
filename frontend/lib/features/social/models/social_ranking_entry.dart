import '../helpers/social_model_parsers.dart';

class SocialRankingEntry {
  const SocialRankingEntry({
    required this.id,
    required this.userId,
    required this.name,
    required this.avatarUrl,
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
  final int points;
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
      points: socialToInt(json['points']),
      streakDays: socialToInt(json['streakDays']),
      isCurrentUser: json['isCurrentUser'] == true,
      isLeader: json['isLeader'] == true,
      position: socialToInt(json['position']),
      subtitle: json['subtitle']?.toString() ?? 'Sequência',
    );
  }
}
