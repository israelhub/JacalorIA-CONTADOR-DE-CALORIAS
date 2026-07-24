import '../helpers/social_model_parsers.dart';

class SocialFriendProfile {
  const SocialFriendProfile({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.avatarFrameId,
    required this.avatarBackgroundId,
    required this.streakDays,
    required this.longestStreakDays,
    required this.missionsCompleted,
    required this.cosmeticsOwned,
    required this.friendCount,
    required this.totalXp,
    required this.favoriteDish,
    required this.preferredPeriod,
    required this.birthDate,
    required this.objective,
    required this.sex,
    required this.createdAt,
    this.isFriend = false,
    this.isSelf = false,
    this.friendRequestStatus = 'none',
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final String? avatarFrameId;
  final String? avatarBackgroundId;
  final int streakDays;
  final int longestStreakDays;
  final int missionsCompleted;
  final int cosmeticsOwned;
  final int friendCount;
  final int totalXp;
  final String? favoriteDish;
  final String? preferredPeriod;
  final String? birthDate;
  final String? objective;
  final String? sex;
  final DateTime? createdAt;
  final bool isFriend;
  final bool isSelf;
  final String friendRequestStatus;

  bool get isOutgoingRequest => friendRequestStatus == 'outgoing';
  bool get isIncomingRequest => friendRequestStatus == 'incoming';
  bool get canSendRequest =>
      !isFriend && !isSelf && !isOutgoingRequest && !isIncomingRequest;

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
      longestStreakDays: socialToInt(
        json['longestStreakDays'] ?? json['longest_streak_days'],
      ),
      missionsCompleted: socialToInt(
        json['missionsCompleted'] ?? json['missions_completed'],
      ),
      cosmeticsOwned: socialToInt(
        json['cosmeticsOwned'] ?? json['cosmetics_owned'],
      ),
      friendCount: socialToInt(json['friendCount']),
      totalXp: socialToInt(json['totalXp']),
      favoriteDish: json['favoriteDish']?.toString(),
      preferredPeriod: json['preferredPeriod']?.toString(),
      birthDate: json['birthDate']?.toString(),
      objective: json['objective']?.toString(),
      sex: json['sex']?.toString(),
      createdAt: DateTime.tryParse(
        (json['createdAt'] ?? json['created_at'])?.toString() ?? '',
      ),
      isFriend: json['isFriend'] == true,
      isSelf: json['isSelf'] == true,
      friendRequestStatus:
          json['friendRequestStatus']?.toString() ?? 'none',
    );
  }

  SocialFriendProfile copyWith({
    bool? isFriend,
    String? friendRequestStatus,
  }) {
    return SocialFriendProfile(
      id: id,
      name: name,
      avatarUrl: avatarUrl,
      avatarFrameId: avatarFrameId,
      avatarBackgroundId: avatarBackgroundId,
      streakDays: streakDays,
      longestStreakDays: longestStreakDays,
      missionsCompleted: missionsCompleted,
      cosmeticsOwned: cosmeticsOwned,
      friendCount: friendCount,
      totalXp: totalXp,
      favoriteDish: favoriteDish,
      preferredPeriod: preferredPeriod,
      birthDate: birthDate,
      objective: objective,
      sex: sex,
      createdAt: createdAt,
      isFriend: isFriend ?? this.isFriend,
      isSelf: isSelf,
      friendRequestStatus: friendRequestStatus ?? this.friendRequestStatus,
    );
  }
}
