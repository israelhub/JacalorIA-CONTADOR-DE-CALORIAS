import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_confirm_modal.dart';
import '../../../shared/widgets/app_page_route.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/avatar_profile_preview.dart';
import '../models/social_group_models.dart';
import '../services/social_service.dart';
import '../widgets/social_profile_info_card.dart';
import '../widgets/social_profile_metric_card.dart';
import 'social_user_friends_page.dart';

class SocialFriendProfilePage extends StatefulWidget {
  const SocialFriendProfilePage({
    super.key,
    required this.friendId,
    this.initialFriendName,
    this.groupId,
    this.viaUserId,
    SocialService? service,
  }) : service = service ?? const SocialService();

  final String friendId;
  final String? initialFriendName;
  final String? groupId;
  final String? viaUserId;
  final SocialService service;

  @override
  State<SocialFriendProfilePage> createState() =>
      _SocialFriendProfilePageState();
}

class _SocialFriendProfilePageState extends State<SocialFriendProfilePage> {
  SocialFriendProfile? _profile;
  bool _isLoading = true;
  bool _isRemovingFriend = false;
  bool _isAddingFriend = false;
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
      final data = await widget.service.fetchFriendProfile(
        widget.friendId,
        groupId: widget.groupId,
        viaUserId: widget.viaUserId,
      );
      if (!mounted) return;
      setState(() {
        _profile = data;
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

  Future<void> _openFriendsList() async {
    final profile = _profile;
    if (profile == null) return;

    await context.pushSlidePage<void>(
      SocialUserFriendsPage(
        userId: profile.id,
        userName: profile.name,
        groupId: widget.groupId,
        viaUserId: widget.viaUserId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.brand900Variant,
        title: Text(
          widget.initialFriendName?.trim().isNotEmpty == true
              ? widget.initialFriendName!
              : 'Perfil',
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
            : _buildProfile(),
      ),
    );
  }

  Widget _buildProfile() {
    final profile = _profile;
    if (profile == null) return const SizedBox.shrink();

    final preferredPeriod = switch (profile.preferredPeriod) {
      'morning' => 'Manhã',
      'afternoon' => 'Tarde',
      'night' => 'Noite',
      _ => 'Sem registros',
    };

    final objective = _formatObjective(profile.objective);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AvatarProfilePreview(
            avatarUrl: profile.avatarUrl,
            frameId: profile.avatarFrameId,
            backgroundId: profile.avatarBackgroundId,
            name: profile.name,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.missionsTitle.copyWith(
                              color: AppColors.brand900Variant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          InkWell(
                            onTap: _openFriendsList,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 2,
                              ),
                              child: Text(
                                '${profile.friendCount} amigos',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.action500,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!profile.isSelf) ...[
                      const SizedBox(width: AppSpacing.md),
                      _buildHeaderFriendshipSlot(profile),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _sectionTitle('Resumo'),
                const SizedBox(height: AppSpacing.sm),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth;
                    final spacing = AppSpacing.md;
                    const columns = 2;
                    final availableWidth = maxWidth - (spacing * (columns - 1));
                    final cardWidth = availableWidth > 0
                        ? availableWidth / columns
                        : maxWidth;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: AppSpacing.md,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: _metricCard(
                            icon: Icons.local_fire_department_rounded,
                            iconColor: AppColors.socialMetricStreak,
                            label: 'Sequência',
                            value: '${profile.streakDays} dias',
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _metricCard(
                            icon: Icons.restaurant_menu_rounded,
                            iconColor: AppColors.socialMetricFavoriteDish,
                            label: 'Prato favorito',
                            value:
                                profile.favoriteDish?.trim().isNotEmpty == true
                                ? profile.favoriteDish!
                                : 'Sem registros',
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _metricCard(
                            icon: Icons.schedule_rounded,
                            iconColor: AppColors.socialMetricPreferredPeriod,
                            label: 'Come mais de',
                            value: preferredPeriod,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _metricCard(
                            icon: Icons.auto_awesome_rounded,
                            iconColor: AppColors.socialMetricXp,
                            label: 'Total de XP',
                            value: '${profile.totalXp}',
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                _sectionTitle('Informações'),
                const SizedBox(height: AppSpacing.sm),
                _infoCard(
                  icon: Icons.flag_rounded,
                  iconColor: AppColors.socialInfoObjective,
                  label: 'Objetivo',
                  value: objective,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String value) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        value,
        style: AppTextStyles.missionsSectionTitle.copyWith(
          color: AppColors.brand900Variant,
        ),
      ),
    );
  }

  Widget _metricCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return SocialProfileMetricCard(
      icon: icon,
      iconColor: iconColor,
      label: label,
      value: value,
    );
  }

  Widget _infoCard({
    Widget? iconWidget,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return SocialProfileInfoCard(
      iconWidget: iconWidget,
      icon: icon,
      iconColor: iconColor,
      label: label,
      value: value,
    );
  }

  Widget _buildHeaderFriendshipSlot(SocialFriendProfile profile) {
    return Flexible(
      child: Align(
        alignment: Alignment.centerRight,
        child: _buildFriendshipAction(profile),
      ),
    );
  }

  Widget _buildFriendshipAction(SocialFriendProfile profile) {
    if (profile.isFriend) {
      return _CompactFriendshipButton(
        label: 'Amigos',
        icon: Icons.people_alt_rounded,
        filled: false,
        onPressed: _isRemovingFriend ? null : _onRemoveFriendPressed,
      );
    }

    if (profile.isOutgoingRequest) {
      return const _CompactFriendshipButton(
        label: 'Solicitado',
        icon: Icons.hourglass_top_rounded,
        filled: false,
        onPressed: null,
      );
    }

    if (profile.isIncomingRequest) {
      return const _CompactFriendshipButton(
        label: 'Solicitou você',
        icon: Icons.person_add_alt_1_rounded,
        filled: false,
        onPressed: null,
      );
    }

    return _CompactFriendshipButton(
      label: 'Adicionar amigo',
      icon: Icons.person_add_alt_1_rounded,
      filled: true,
      onPressed: _isAddingFriend ? null : _onAddFriendPressed,
    );
  }

  Future<void> _onAddFriendPressed() async {
    setState(() => _isAddingFriend = true);
    try {
      await widget.service.addFriendById(widget.friendId);
      if (!mounted) return;
      setState(() {
        _profile = _profile?.copyWith(friendRequestStatus: 'outgoing');
        _isAddingFriend = false;
      });
      AppToast.show(context, message: 'Solicitação de amizade enviada');
    } catch (error) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
      setState(() => _isAddingFriend = false);
    }
  }

  Future<void> _onRemoveFriendPressed() async {
    final shouldRemove = await AppConfirmModal.show(
      context,
      title: 'Desfazer amizade?',
      message: 'Você pode adicionar novamente depois.',
      confirmLabel: 'Desfazer',
      cancelLabel: 'Manter',
      isDanger: true,
    );
    if (!shouldRemove) return;

    setState(() => _isRemovingFriend = true);
    try {
      await widget.service.removeFriend(widget.friendId);
      if (!mounted) return;
      AppToast.show(context, message: 'Amizade desfeita com sucesso');
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
      setState(() => _isRemovingFriend = false);
    }
  }

  String _normalizeLabel(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return 'Não informado';
    return raw[0].toUpperCase() +
        raw.substring(1).toLowerCase().replaceAll('_', ' ');
  }

  String _formatObjective(String? value) {
    final raw = (value ?? '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z]'), '');
    if (raw.isEmpty) return 'Não informado';

    const labels = <String, String>{
      'loseweight': 'Emagrecer',
      'losewight': 'Emagrecer',
      'weightloss': 'Emagrecer',
      'cut': 'Emagrecer',
      'maintainweight': 'Manter peso',
      'maintenance': 'Manter peso',
      'maintain': 'Manter peso',
      'gainweight': 'Ganhar massa',
      'weightgain': 'Ganhar massa',
      'gainmass': 'Ganhar massa',
      'bulk': 'Ganhar massa',
      'gainmuscle': 'Ganhar massa',
      'musclegain': 'Ganhar massa',
      'recomposition': 'Recomposição corporal',
    };

    return labels[raw] ?? _normalizeLabel(value);
  }
}

class _CompactFriendshipButton extends StatelessWidget {
  const _CompactFriendshipButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final foreground = filled ? Colors.white : AppColors.action500;
    final background = filled ? AppColors.action500 : AppColors.surface;

    return Opacity(
      opacity: enabled ? 1 : 0.7,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: filled
                  ? null
                  : Border.all(color: AppColors.borderAlt),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.captionStrong.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
