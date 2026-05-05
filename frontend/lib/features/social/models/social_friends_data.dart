import 'social_friend.dart';

class SocialFriendsData {
  const SocialFriendsData({required this.friends, required this.inviteCode});

  final List<SocialFriend> friends;
  final String inviteCode;
}
