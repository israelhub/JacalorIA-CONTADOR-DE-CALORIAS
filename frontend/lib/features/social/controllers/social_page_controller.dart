import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/api_config.dart';
import '../../auth/service/auth_service.dart';
import '../models/social_group_models.dart';
import '../services/social_service.dart';

class SocialPageController extends ChangeNotifier {
  SocialPageController({SocialService? service, AuthService? authService})
    : _service = service ?? const SocialService(),
      _authService = authService ?? AuthService();

  final SocialService _service;
  final AuthService _authService;

  final List<SocialGroupSummary> _groups = <SocialGroupSummary>[];
  final List<SocialFriend> _friends = <SocialFriend>[];
  final List<SocialFriendRequest> _pendingFriendRequests =
      <SocialFriendRequest>[];

  List<SocialGroupSummary> get groups =>
      List<SocialGroupSummary>.unmodifiable(_groups);
  List<SocialFriend> get friends => List<SocialFriend>.unmodifiable(_friends);
  List<SocialFriendRequest> get pendingFriendRequests =>
      List<SocialFriendRequest>.unmodifiable(_pendingFriendRequests);
  int get pendingFriendRequestCount => _pendingFriendRequests.length;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _hasLoadedOnce = false;
  bool get hasLoadedOnce => _hasLoadedOnce;

  bool _showIntro = false;
  bool get showIntro => _showIntro;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _friendInviteCode = '';
  String get friendInviteCode => _friendInviteCode;

  /// Short alphanumeric code for sharing/adding friends (not the internal UUID).
  String get shareableFriendId => _friendInviteCode.trim().toUpperCase();

  String _currentUserId = '';
  String get currentUserId => _currentUserId;

  String _currentUserName = 'Seu perfil';
  String get currentUserName => _currentUserName;

  String? _currentUserAvatarUrl;
  String? get currentUserAvatarUrl => _currentUserAvatarUrl;
  String? _currentUserAvatarFrameId;
  String? get currentUserAvatarFrameId => _currentUserAvatarFrameId;

  int _tabIndex = 0;
  int get tabIndex => _tabIndex;

  int _previousTabIndex = 0;
  int get previousTabIndex => _previousTabIndex;
  static const String _viewedFinishedGroupsKey =
      'social_viewed_finished_groups';
  static const String _hideIntroLocalKeyPrefix = 'social_hide_intro_local';
  final Set<String> _viewedFinishedGroupIds = <String>{};

  String _hideIntroLocalKeyForUserId(String userId) {
    final normalized = userId.trim().isEmpty ? 'user' : userId.trim();
    return '$_hideIntroLocalKeyPrefix:$normalized';
  }

  String _resolveLocalUserId() {
    final authUser = AuthService.globalUser;
    final rawUserId =
        authUser?['id'] ?? authUser?['email'] ?? authUser?['name'] ?? 'user';
    return rawUserId.toString();
  }

  Future<bool> _readHideIntroLocal(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hideIntroLocalKeyForUserId(userId)) ?? false;
  }

  bool _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  bool _isGuideHidden(Map<String, dynamic> profile) {
    return _asBool(profile['hideGuideMe']) ||
        _asBool(profile['hideSocialGuideMe']) ||
        _asBool(profile['hideMissionsGuideMe']) ||
        _asBool(profile['hide_guide_me']) ||
        _asBool(profile['hide_social_guide_me']) ||
        _asBool(profile['hide_missions_guide_me']);
  }

  Future<void> loadAll({bool silent = false}) async {
    final hadData = _hasLoadedOnce;
    final localUserId = _resolveLocalUserId();
    try {
      if (await _readHideIntroLocal(localUserId)) {
        _showIntro = false;
      }
    } catch (_) {}

    // Keep showing cached content while refreshing in the background.
    final nextLoading = silent ? false : !hadData;
    final shouldAnnounceLoading =
        !silent ||
        !hadData ||
        _isLoading != nextLoading ||
        _errorMessage != null;
    _isLoading = nextLoading;
    _errorMessage = null;
    if (shouldAnnounceLoading) {
      notifyListeners();
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _viewedFinishedGroupIds
        ..clear()
        ..addAll(
          prefs.getStringList(_viewedFinishedGroupsKey) ?? const <String>[],
        );

      final results = await Future.wait<dynamic>([
        _service.fetchGroups(),
        _service.fetchFriends(),
        _authService.fetchProfile(),
      ]);
      final groups = results[0] as List<SocialGroupSummary>;
      final friendsData = results[1] as SocialFriendsData;
      final canonicalProfile = results[2] as Map<String, dynamic>;
      AuthService.globalUser = canonicalProfile;
      final canonicalUserId =
          canonicalProfile['id']?.toString() ??
          canonicalProfile['email']?.toString() ??
          canonicalProfile['name']?.toString() ??
          localUserId;
      final hideIntroLocal = await _readHideIntroLocal(canonicalUserId);

      _groups
        ..clear()
        ..addAll(groups);
      _applyFriendsData(friendsData);
      final profile = canonicalProfile;
      _currentUserId = profile['id']?.toString() ?? '';
      _currentUserName = profile['name']?.toString().trim().isNotEmpty == true
          ? profile['name'].toString()
          : 'Seu perfil';
      _currentUserAvatarUrl = profile['avatarUrl']?.toString();
      _currentUserAvatarFrameId = profile['equippedAvatarFrameId']?.toString();
      _showIntro = !(hideIntroLocal || _isGuideHidden(profile));
      _hasLoadedOnce = true;
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _isLoading = false;
      if (!silent || !hadData) {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      }
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
        'hideGuideMe': true,
        'hideSocialGuideMe': true,
        'hideMissionsGuideMe': true,
      });
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        _hideIntroLocalKeyForUserId(_resolveLocalUserId()),
        true,
      );
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
    _applyFriendsData(data);
    notifyListeners();
  }

  Future<void> addFriendByLink(String code) async {
    final data = await _service.addFriendByLinkCode(code);
    _applyFriendsData(data);
    notifyListeners();
  }

  Future<void> addFriendById(String userId) async {
    final data = await _service.addFriendById(userId);
    _applyFriendsData(data);
    notifyListeners();
  }

  Future<void> acceptFriendRequest(String requestId) async {
    final data = await _service.acceptFriendRequest(requestId);
    _applyFriendsData(data);
    notifyListeners();
  }

  Future<void> rejectFriendRequest(String requestId) async {
    final data = await _service.rejectFriendRequest(requestId);
    _applyFriendsData(data);
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
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return Future.value(const <SocialUserSearchResult>[]);
    }

    // Keep name/email searches as-typed; only normalize invite links / codes.
    final looksLikeEmail = trimmed.contains('@');
    final looksLikeUuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    ).hasMatch(trimmed);
    final looksLikeInviteCode = RegExp(
      r'^[A-Za-z0-9]{4,12}$',
    ).hasMatch(trimmed);
    final looksLikeInviteLink =
        trimmed.toLowerCase().contains('friend') ||
        trimmed.toLowerCase().contains('code=') ||
        trimmed.toUpperCase().startsWith('JACALORIA-FRIEND-');

    if (!looksLikeEmail &&
        !looksLikeUuid &&
        (looksLikeInviteCode || looksLikeInviteLink)) {
      final normalized = extractInviteCode(trimmed);
      return _service.searchUsers(normalized.isNotEmpty ? normalized : trimmed);
    }

    return _service.searchUsers(trimmed);
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
      final lower = lastSegment.toLowerCase();
      if (lastSegment.isNotEmpty && lower != 'friend' && lower != 'group') {
        return lastSegment.toUpperCase();
      }
    }

    return raw.replaceAll('JACALORIA-FRIEND-', '').trim().toUpperCase();
  }

  bool isFinalResultViewed(String groupId) =>
      _viewedFinishedGroupIds.contains(groupId);

  Future<void> markFinalResultViewed(String groupId) async {
    if (groupId.trim().isEmpty || _viewedFinishedGroupIds.contains(groupId))
      return;
    _viewedFinishedGroupIds.add(groupId);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _viewedFinishedGroupsKey,
      _viewedFinishedGroupIds.toList(growable: false),
    );
  }

  void _applyFriendsData(SocialFriendsData data) {
    _friends
      ..clear()
      ..addAll(data.friends);
    _pendingFriendRequests
      ..clear()
      ..addAll(data.pendingRequests);
    _friendInviteCode = data.inviteCode;
  }
}
