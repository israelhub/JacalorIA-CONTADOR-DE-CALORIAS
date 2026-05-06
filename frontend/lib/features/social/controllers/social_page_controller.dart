import 'package:flutter/foundation.dart';

import '../../../core/config/api_config.dart';
import '../../auth/service/auth_service.dart';
import '../models/social_group_models.dart';
import '../services/social_service.dart';

class SocialPageController extends ChangeNotifier {
  SocialPageController({SocialService? service})
    : _service = service ?? const SocialService();

  final SocialService _service;
  final AuthService _authService = AuthService();

  final List<SocialGroupSummary> _groups = <SocialGroupSummary>[];
  final List<SocialFriend> _friends = <SocialFriend>[];

  List<SocialGroupSummary> get groups => List<SocialGroupSummary>.unmodifiable(_groups);
  List<SocialFriend> get friends => List<SocialFriend>.unmodifiable(_friends);

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _showIntro = true;
  bool get showIntro => _showIntro;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _friendInviteCode = '';
  String get friendInviteCode => _friendInviteCode;

  String _currentUserId = '';
  String get currentUserId => _currentUserId;

  String _currentUserName = 'Seu perfil';
  String get currentUserName => _currentUserName;

  String? _currentUserAvatarUrl;
  String? get currentUserAvatarUrl => _currentUserAvatarUrl;

  int _tabIndex = 0;
  int get tabIndex => _tabIndex;

  int _previousTabIndex = 0;
  int get previousTabIndex => _previousTabIndex;

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final groups = await _service.fetchGroups();
      final friendsData = await _service.fetchFriends();
      final canonicalProfile = await _authService.fetchProfile();
      AuthService.globalUser = canonicalProfile;

      _groups
        ..clear()
        ..addAll(groups);
      _friends
        ..clear()
        ..addAll(friendsData.friends);
      _friendInviteCode = friendsData.inviteCode;
      final profile = canonicalProfile;
      _currentUserId = profile['id']?.toString() ?? '';
      _currentUserName = profile['name']?.toString().trim().isNotEmpty == true
          ? profile['name'].toString()
          : 'Seu perfil';
      _currentUserAvatarUrl = profile['avatarUrl']?.toString();
      final hideSocialGuideMe =
          profile['hideSocialGuideMe'] == true || profile['hideGuideMe'] == true;
      _showIntro = !hideSocialGuideMe;
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  void hideIntro() {
    if (!_showIntro) return;
    _showIntro = false;
    notifyListeners();
    _persistGuidePreference();
  }

  Future<void> _persistGuidePreference() async {
    try {
      await _authService.updateProfile(<String, dynamic>{
        'hideSocialGuideMe': true,
      });
    } catch (_) {}
  }

  void changeTab(int index) {
    if (_tabIndex == index) return;
    _previousTabIndex = _tabIndex;
    _tabIndex = index;
    notifyListeners();
  }

  Future<void> addFriendByEmail(String email) async {
    final data = await _service.addFriendByEmail(email);
    _friends
      ..clear()
      ..addAll(data.friends);
    _friendInviteCode = data.inviteCode;
    notifyListeners();
  }

  Future<void> addFriendByLink(String code) async {
    final data = await _service.addFriendByLinkCode(code);
    _friends
      ..clear()
      ..addAll(data.friends);
    _friendInviteCode = data.inviteCode;
    notifyListeners();
  }

  Future<void> addFriendById(String userId) async {
    final data = await _service.addFriendById(userId);
    _friends
      ..clear()
      ..addAll(data.friends);
    _friendInviteCode = data.inviteCode;
    notifyListeners();
  }

  Future<SocialGroupDetail> joinGroupByCode(String code) async {
    final detail = await _service.joinGroupByInviteCode(code);
    _groups.insert(0, detail.group);
    notifyListeners();
    return detail;
  }

  void addGroup(SocialGroupSummary group) {
    _groups.insert(0, group);
    notifyListeners();
  }

  Future<List<SocialUserSearchResult>> searchUsers(String query) {
    return _service.searchUsers(query);
  }

  String friendLinkValue() {
    final inviteCode = _friendInviteCode.trim().toUpperCase();
    return '${ApiConfig.shareBaseUrl}/friend?code=$inviteCode';
  }

  String extractInviteCode(String rawValue) {
    final raw = rawValue.trim();
    if (raw.isEmpty) return raw;
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.queryParameters.containsKey('code')) {
      final code = uri.queryParameters['code'] ?? '';
      if (code.isNotEmpty) {
        return code.trim().toUpperCase();
      }
    }
    if (uri != null && uri.pathSegments.isNotEmpty) {
      final lastSegment = uri.pathSegments.last.trim();
      if (lastSegment.isNotEmpty && lastSegment.toLowerCase() != 'friend') {
        return lastSegment.toUpperCase();
      }
    }

    return raw.replaceAll('JACALORIA-FRIEND-', '').trim().toUpperCase();
  }
}
