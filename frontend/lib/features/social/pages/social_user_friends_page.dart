import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_page_route.dart';
import '../models/social_group_models.dart';
import '../services/social_service.dart';
import '../widgets/social_empty_state.dart';
import '../widgets/social_friend_list_item.dart';
import 'social_friend_profile_page.dart';

class SocialUserFriendsPage extends StatefulWidget {
  const SocialUserFriendsPage({
    super.key,
    required this.userId,
    this.userName,
    this.groupId,
    this.viaUserId,
    SocialService? service,
  }) : service = service ?? const SocialService();

  final String userId;
  final String? userName;
  final String? groupId;
  final String? viaUserId;
  final SocialService service;

  @override
  State<SocialUserFriendsPage> createState() => _SocialUserFriendsPageState();
}

class _SocialUserFriendsPageState extends State<SocialUserFriendsPage> {
  List<SocialFriend> _friends = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final friends = await widget.service.fetchUserFriends(
        widget.userId,
        groupId: widget.groupId,
        viaUserId: widget.viaUserId,
      );
      if (!mounted) return;
      setState(() {
        _friends = friends;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _openFriendProfile(SocialFriend friend) async {
    await context.pushSlidePage<void>(
      SocialFriendProfilePage(
        friendId: friend.id,
        initialFriendName: friend.name,
        groupId: widget.groupId,
        viaUserId: widget.userId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ownerName = widget.userName?.trim();
    final title = ownerName == null || ownerName.isEmpty
        ? 'Amigos'
        : 'Amigos de $ownerName';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.brand900Variant,
        title: Text(
          title,
          style: AppTextStyles.missionsSectionTitle.copyWith(
            color: AppColors.brand900Variant,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.action500),
              )
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            : _friends.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: SocialEmptyState(
                  icon: Icons.people_alt_outlined,
                  title: 'Nenhum amigo ainda',
                  subtitle: 'Quando houver amigos, eles aparecerão aqui.',
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: _friends.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final friend = _friends[index];
                  return SocialFriendListItem(
                    friend: friend,
                    onTap: () => _openFriendProfile(friend),
                  );
                },
              ),
      ),
    );
  }
}
