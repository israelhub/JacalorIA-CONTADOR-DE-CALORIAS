class SocialUserSearchResult {
  const SocialUserSearchResult({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.avatarFrameId,
    required this.isFriend,
    required this.friendRequestStatus,
  });

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? avatarFrameId;
  final bool isFriend;
  final String friendRequestStatus;

  bool get isOutgoingRequest => friendRequestStatus == 'outgoing';
  bool get isIncomingRequest => friendRequestStatus == 'incoming';
  bool get canSendRequest => !isFriend && !isOutgoingRequest && !isIncomingRequest;

  factory SocialUserSearchResult.fromJson(Map<String, dynamic> json) {
    return SocialUserSearchResult(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Sem nome',
      email: json['email']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      avatarFrameId: json['avatarFrameId']?.toString(),
      isFriend: json['isFriend'] == true,
      friendRequestStatus: json['friendRequestStatus']?.toString() ?? 'none',
    );
  }
}
