import '../helpers/social_model_parsers.dart';

class SocialFriendProfile {
  const SocialFriendProfile({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.avatarFrameId,
    required this.avatarBackgroundId,
    required this.streakDays,
    required this.friendCount,
    required this.totalXp,
    required this.favoriteDish,
    required this.preferredPeriod,
    required this.birthDate,
    required this.objective,
    required this.sex,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final String? avatarFrameId;
  final String? avatarBackgroundId;
  final int streakDays;
  final int friendCount;
  final int totalXp;
  final String? favoriteDish;
  final String? preferredPeriod;
  final String? birthDate;
  final String? objective;
  final String? sex;

  factory SocialFriendProfile.fromJson(Map<String, dynamic> json) {
    return SocialFriendProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Sem nome',
      avatarUrl: json['avatarUrl']?.toString(),
      avatarFrameId: json['avatarFrameId']?.toString(),
      avatarBackgroundId:
          json['avatarBackgroundId']?.toString() ??
          json['avatar_background_id']?.toString() ??
          json['equippedAvatarBackgroundId']?.toString() ??
          json['equipped_avatar_background_id']?.toString(),
      streakDays: socialToInt(json['streakDays']),
      friendCount: socialToInt(json['friendCount']),
      totalXp: socialToInt(json['totalXp']),
      favoriteDish: json['favoriteDish']?.toString(),
      preferredPeriod: json['preferredPeriod']?.toString(),
      birthDate: json['birthDate']?.toString(),
      objective: json['objective']?.toString(),
      sex: json['sex']?.toString(),
    );
  }
}
