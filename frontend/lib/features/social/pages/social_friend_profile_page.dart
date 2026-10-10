import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_ambient_page_glow.dart';
import '../../../shared/widgets/app_back_page_header.dart';
import '../../../shared/widgets/app_confirm_modal.dart';
import '../../../shared/widgets/app_page_route.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/avatar_profile_preview.dart';
import '../../home/widgets/home_shell_layout.dart';
import '../../profile/helpers/profile_date_helpers.dart';
import '../../profile/widgets/profile_achievements_card.dart';
import '../../profile/widgets/profile_section_card.dart';
import '../helpers/social_model_parsers.dart';
import '../models/social_group_models.dart';
import '../services/social_service.dart';
import '../widgets/social_member_daily_meals_section.dart';
import '../widgets/social_member_daily_workouts_section.dart';
import '../widgets/social_profile_info_card.dart';
import '../widgets/social_profile_metric_card.dart';
import 'social_user_friends_page.dart';

class SocialFriendProfilePage extends StatefulWidget {
  const SocialFriendProfilePage({
    super.key,
    required this.friendId,
    this.initialFriendName,
    this.groupId,
    this.competitionType,
    this.viaUserId,
    SocialService? service,
  }) : service = service ?? const SocialService();

  final String friendId;
  final String? initialFriendName;
  final String? groupId;
  final String? competitionType;
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
    // Semente SWR: pinta o perfil do cache na hora (sem spinner) e, como a
    // seção de refeições monta junto, o fetch dela roda em paralelo com a
    // revalidação do perfil.
    _profile = SocialService.cachedFriendProfile(
      widget.friendId,
      groupId: widget.groupId,
      viaUserId: widget.viaUserId,
    );
    _isLoading = _profile == null;
    _load(silent: _profile != null);
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

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
      if (silent) {
        // Revalidação em segundo plano falhou; mantém o conteúdo atual.
        return;
      }
      setState(() {
        _error = socialFriendlyError(
          error,
          fallback: 'Não foi possível carregar o perfil. Tente de novo.',
        );
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
        competitionType: widget.competitionType,
        viaUserId: widget.viaUserId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBackPageHeader(
        title: widget.initialFriendName?.trim().isNotEmpty == true
            ? widget.initialFriendName!
            : 'Perfil',
        backgroundColor: Colors.transparent,
      ),
      body: AppAmbientPageBody(
        child: SafeArea(
          top: false,
          bottom: false,
          child: _isLoading
              ? const _FriendProfileSkeleton()
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
    final topInset = MediaQuery.paddingOf(context).top;
    final bannerOverlayHeight = topInset + AppBackPageHeader.barHeight;
    final bannerComposeHeight = AvatarProfilePreview.edgeToEdgeComposeHeight(
      topOverlayHeight: bannerOverlayHeight,
    );
    final bannerHeight = AvatarProfilePreview.edgeToEdgeHeight(
      topOverlayHeight: bannerOverlayHeight,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: homeShellScrollBottomInset(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AvatarProfilePreview(
            avatarUrl: profile.avatarUrl,
            frameId: profile.avatarFrameId,
            reactionEmojiId: profile.profileReactionEmojiId,
            name: profile.name,
            height: bannerHeight,
            composeHeight: bannerComposeHeight,
            borderRadius: BorderRadius.zero,
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              profile.name,
                              textAlign: TextAlign.left,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.missionsTitle.copyWith(
                                color: AppColors.brand900Variant,
                              ),
                            ),
                          ),
                          if (!profile.isSelf) ...[
                            const SizedBox(width: AppSpacing.md),
                            _buildHeaderFriendshipSlot(profile),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      InkWell(
                        onTap: _openFriendsList,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
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
                const SizedBox(height: AppSpacing.xl),
                ProfileSectionCard(
                  title: 'Resumo',
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth;
                      final spacing = AppSpacing.md;
                      const columns = 2;
                      final availableWidth =
                          maxWidth - (spacing * (columns - 1));
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
                                  profile.favoriteDish?.trim().isNotEmpty ==
                                      true
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
                ),
                const SizedBox(height: AppSpacing.cardGap),
                ProfileSectionCard(
                  title: 'Informações',
                  child: Column(
                    children: [
                      _infoCard(
                        icon: Icons.flag_rounded,
                        iconColor: AppColors.socialInfoObjective,
                        label: 'Objetivo',
                        value: objective,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _infoCard(
                        icon: Icons.schedule_rounded,
                        iconColor: AppColors.socialInfoSex,
                        label: 'Idade da conta',
                        value: formatProfileAccountAge(profile.createdAt),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.cardGap),
                ProfileSectionCard(
                  title: 'Conquistas',
                  child: ProfileAchievementsCard(
                    missionsCompleted: profile.missionsCompleted,
                    longestStreakDays: profile.longestStreakDays,
                    cosmeticsOwned: profile.cosmeticsOwned,
                  ),
                ),
                SocialMemberDailyMealsSection(
                  memberUserId: profile.id,
                  groupId: widget.groupId,
                  viaUserId: widget.viaUserId,
                  service: widget.service,
                  readOnly: !profile.isSelf,
                ),
                SocialMemberDailyWorkoutsSection(
                  memberUserId: profile.id,
                  groupId: widget.groupId,
                  viaUserId: widget.viaUserId,
                  service: widget.service,
                ),
              ],
            ),
          ),
        ],
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
    final raw = (value ?? '').trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z]'),
      '',
    );
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
              border: filled ? null : Border.all(color: AppColors.borderAlt),
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

class _FriendProfileSkeleton extends StatelessWidget {
  const _FriendProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final bannerHeight = topInset + AppBackPageHeader.barHeight + 180;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: homeShellScrollBottomInset(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSkeletonBox(height: bannerHeight, borderRadius: 0),
          const SizedBox(height: AppSpacing.lg),
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSkeletonBox(height: 22, width: 160),
                SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(child: AppSkeletonBox(height: 72)),
                    SizedBox(width: AppSpacing.md),
                    Expanded(child: AppSkeletonBox(height: 72)),
                  ],
                ),
                SizedBox(height: AppSpacing.cardGap),
                AppSkeletonBox(height: 120),
                SizedBox(height: AppSpacing.cardGap),
                AppSkeletonBox(height: 160),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
