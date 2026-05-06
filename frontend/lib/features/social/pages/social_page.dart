import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_guide_card.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_page_route.dart';
import '../controllers/social_page_controller.dart';
import '../models/social_group_models.dart';
import 'social_friend_profile_page.dart';
import 'social_group_detail_page.dart';
import 'social_friends_tab_page.dart';
import 'social_groups_tab_page.dart';
import '../services/social_service.dart';
import '../widgets/social_create_group_sheet.dart';
import '../widgets/social_add_friend_dialog.dart';
import '../widgets/social_join_group_dialog.dart';
import '../widgets/social_public_groups_dialog.dart';
import '../widgets/social_qr_scan_sheet.dart';
import '../widgets/social_search_user_dialog.dart';
import '../widgets/social_segmented_control.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key, SocialService? service})
    : service = service ?? const SocialService();

  final SocialService service;

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> {
  static const Duration _tabTransitionDuration = Duration(milliseconds: 320);
  late final SocialPageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SocialPageController(service: widget.service);
    _controller.loadAll();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.surface,
          body: SafeArea(child: _buildContent()),
        );
      },
    );
  }

  Widget _buildContent() {
    if (_controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.action500),
      );
    }

    if (_controller.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _controller.errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: 'Tentar novamente', onPressed: _controller.loadAll),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppPageHeader(title: 'Social', icon: Icons.groups_2_rounded),
          const SizedBox(height: AppSpacing.lg),
          SocialSegmentedControl(
            selectedIndex: _controller.tabIndex,
            labels: const ['Amigos', 'Grupos'],
            onChanged: _controller.changeTab,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_controller.showIntro) ...[
            AppGuideCard(
              title: 'Conte calorias com seus amigos',
              description:
                  'Adicione amigos por e-mail ou link. Crie grupos e compartilhe links de entrada.',
              icon: Icons.emoji_events_rounded,
              onClose: _controller.hideIntro,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          AnimatedSwitcher(
            duration: _tabTransitionDuration,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (currentChild, previousChildren) {
              return currentChild ?? const SizedBox.shrink();
            },
            transitionBuilder: (child, animation) {
              final currentKey = ValueKey<int>(_controller.tabIndex);
              final isIncoming = child.key == currentKey;
              final isForward = _controller.tabIndex > _controller.previousTabIndex;
              final begin = Offset(isForward ? 0.2 : -0.2, 0);
              final end = Offset(isForward ? -0.2 : 0.2, 0);
              final offsetTween = Tween<Offset>(
                begin: isIncoming ? begin : Offset.zero,
                end: isIncoming ? Offset.zero : end,
              );

              return ClipRect(
                child: SlideTransition(
                  position: offsetTween.animate(animation),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(_controller.tabIndex),
              child: _controller.tabIndex == 0
                  ? SocialFriendsTabPage(
                      friends: _controller.friends,
                      onAddFriend: _openAddFriendModal,
                      onOpenFriendProfile: _openFriendProfile,
                    )
                  : SocialGroupsTabPage(
                      groups: _controller.groups,
                      onCreateGroup: _openCreateGroupSheet,
                      onJoinGroup: _openJoinGroupDialog,
                      onOpenGroup: _openGroupDetail,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddFriendModal() async {
    final qrPayload = _controller.friendLinkValue();
    await showDialog<void>(
      context: context,
      builder: (context) => SocialAddFriendDialog(
        userName: _controller.currentUserName,
        userAvatarUrl: _controller.currentUserAvatarUrl,
        qrPayload: qrPayload,
        onCopyId: _copyCurrentUserId,
        onSearchUser: () async {
          Navigator.of(context).pop();
          await _openSearchUserModal();
        },
        onScanQr: () async {
          final value = await _scanQrCode();
          if (value == null || value.trim().isEmpty) return;
          if (!mounted) return;
          Navigator.of(context).pop();
          await _submitFriendLookup(value);
        },
        onShareLink: _shareFriendInviteLink,
      ),
    );
  }

  Future<void> _submitFriendLookup(String value) async {
    if (value.isEmpty) {
      _showError(Exception('Informe um e-mail ou código de convite'));
      return;
    }

    if (value.contains('@')) {
      await _guardedAction(() => _controller.addFriendByEmail(value));
      return;
    }

    final normalized = _controller.extractInviteCode(value);
    final isUuid =
        RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
        ).hasMatch(normalized);
    if (isUuid) {
      await _guardedAction(() => _controller.addFriendById(normalized));
      return;
    }

    await _guardedAction(() => _controller.addFriendByLink(normalized));
  }

  Future<void> _openJoinGroupDialog() async {
    final result = await showDialog<SocialJoinGroupDialogResult>(
      context: context,
      builder: (context) => const SocialJoinGroupDialog(),
    );
    if (result == null) return;

    if (result.openPublicGroups) {
      final selectedGroupId = await showDialog<String>(
        context: context,
        builder: (context) => SocialPublicGroupsDialog(
          fetchGroups: ({
            required String query,
            int? durationDays,
            String? competitionType,
          }) {
            return widget.service.fetchPublicGroups(
              query: query,
              durationDays: durationDays,
              competitionType: competitionType,
            );
          },
        ),
      );
      if (selectedGroupId == null || selectedGroupId.trim().isEmpty) return;
      await _guardedAction(() async {
        final detail = await widget.service.joinPublicGroup(selectedGroupId);
        if (!mounted) return;
        await context.pushSlidePage(
          SocialGroupDetailPage(groupId: detail.group.id, initialDetail: detail),
        );
        if (mounted) await _controller.loadAll();
      });
      return;
    }

    final code = result.code?.trim() ?? '';
    if (code.isEmpty) return;
    await _guardedAction(() async {
      final detail = await _controller.joinGroupByCode(code);
      if (!mounted) return;
      await context.pushSlidePage(
        SocialGroupDetailPage(groupId: detail.group.id, initialDetail: detail),
      );
      if (mounted) await _controller.loadAll();
    });
  }

  Future<void> _openCreateGroupSheet() async {
    final result = await showModalBottomSheet<SocialGroupDetail>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SocialCreateGroupSheet(service: widget.service),
    );

    if (result == null || !mounted) return;
    await context.pushSlidePage(
      SocialGroupDetailPage(groupId: result.group.id, initialDetail: result),
    );
    if (mounted) await _controller.loadAll();
  }

  Future<void> _openGroupDetail(String groupId) async {
    await context.pushSlidePage(SocialGroupDetailPage(groupId: groupId));
    if (mounted) await _controller.loadAll();
  }

  Future<void> _openFriendProfile(SocialFriend friend) async {
    final removed = await context.pushSlidePage<bool>(
      SocialFriendProfilePage(
        friendId: friend.id,
        initialFriendName: friend.name,
        service: widget.service,
      ),
    );
    if (removed == true && mounted) {
      await _controller.loadAll();
    }
  }

  Future<void> _shareFriendInviteLink() async {
    await Share.share(_controller.friendLinkValue());
  }

  Future<void> _openSearchUserModal() async {
    await showDialog<void>(
      context: context,
      builder: (context) => SocialSearchUserDialog(
        searchUsers: _controller.searchUsers,
        onAddUser: (user) async {
          await _guardedAction(() => _controller.addFriendById(user.id));
        },
      ),
    );
  }

  Future<void> _copyCurrentUserId() async {
    if (_controller.currentUserId.isEmpty) {
      _showError(Exception('ID do usuário indisponível no momento'));
      return;
    }

    await Clipboard.setData(ClipboardData(text: _controller.currentUserId));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ID do usuário copiado')),
    );
  }

  Future<String?> _scanQrCode() {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SocialQrScanSheet(),
    );
  }

  Future<void> _guardedAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }
}
