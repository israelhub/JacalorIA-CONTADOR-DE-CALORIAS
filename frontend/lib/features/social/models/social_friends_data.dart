import 'social_friend.dart';
import 'social_friend_request.dart';

class SocialFriendsData {
  const SocialFriendsData({
    required this.friends,
    required this.inviteCode,
    this.pendingRequests = const <SocialFriendRequest>[],
  });

  final List<SocialFriend> friends;
  final String inviteCode;
  final List<SocialFriendRequest> pendingRequests;
}
