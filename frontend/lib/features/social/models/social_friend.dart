import '../helpers/social_model_parsers.dart';

class SocialFriend {
  const SocialFriend({required this.id, required this.name, required this.avatarUrl, required this.streakDays});

  final String id;
  final String name;
  final String? avatarUrl;
  final int streakDays;

  factory SocialFriend.fromJson(Map<String, dynamic> json) {
    return SocialFriend(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Sem nome',
      avatarUrl: json['avatarUrl']?.toString(),
      streakDays: socialToInt(json['streakDays']),
    );
  }
}
