class SocialFriendProfile {
  const SocialFriendProfile({
    required this.id,
    required this.name,
    required this.avatarUrl,
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
  final int streakDays;
  final int friendCount;
  final int totalXp;
  final String? favoriteDish;
  final String? preferredPeriod;
  final String? birthDate;
  final String? objective;
  final String? sex;

  factory SocialFriendProfile.fromJson(Map<String, dynamic> json) {
    int toInt(Object? value) {
      if (value is num) return value.round();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return SocialFriendProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Sem nome',
      avatarUrl: json['avatarUrl']?.toString(),
      streakDays: toInt(json['streakDays']),
      friendCount: toInt(json['friendCount']),
      totalXp: toInt(json['totalXp']),
      favoriteDish: json['favoriteDish']?.toString(),
      preferredPeriod: json['preferredPeriod']?.toString(),
      birthDate: json['birthDate']?.toString(),
      objective: json['objective']?.toString(),
      sex: json['sex']?.toString(),
    );
  }
}
