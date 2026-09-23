class SocialFriendRequest {
  const SocialFriendRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.requesterEmail,
    required this.requesterAvatarUrl,
    required this.requesterAvatarFrameId,
    required this.createdAt,
  });

  final String id;
  final String requesterId;
  final String requesterName;
  final String requesterEmail;
  final String? requesterAvatarUrl;
  final String? requesterAvatarFrameId;
  final DateTime? createdAt;

  factory SocialFriendRequest.fromJson(Map<String, dynamic> json) {
    return SocialFriendRequest(
      id: json['id']?.toString() ?? '',
      requesterId: json['requesterId']?.toString() ?? '',
      requesterName: json['requesterName']?.toString() ?? 'Sem nome',
      requesterEmail: json['requesterEmail']?.toString() ?? '',
      requesterAvatarUrl: json['requesterAvatarUrl']?.toString(),
      requesterAvatarFrameId: json['requesterAvatarFrameId']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
