class SocialUserSearchResult {
  const SocialUserSearchResult({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.isFriend,
  });

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final bool isFriend;

  factory SocialUserSearchResult.fromJson(Map<String, dynamic> json) {
    return SocialUserSearchResult(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Sem nome',
      email: json['email']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      isFriend: json['isFriend'] == true,
    );
  }
}
