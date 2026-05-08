import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_confirm_modal.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/framed_avatar.dart';
import '../../profile/helpers/profile_date_helpers.dart';
import '../models/social_group_models.dart';
import '../services/social_service.dart';
import '../widgets/social_profile_info_card.dart';
import '../widgets/social_profile_metric_card.dart';

class SocialFriendProfilePage extends StatefulWidget {
  const SocialFriendProfilePage({
    super.key,
    required this.friendId,
    this.initialFriendName,
    SocialService? service,
  }) : service = service ?? const SocialService();

  final String friendId;
  final String? initialFriendName;
  final SocialService service;

  @override
  State<SocialFriendProfilePage> createState() =>
      _SocialFriendProfilePageState();
}

class _SocialFriendProfilePageState extends State<SocialFriendProfilePage> {
  SocialFriendProfile? _profile;
  bool _isLoading = true;
  bool _isRemovingFriend = false;
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
      final data = await widget.service.fetchFriendProfile(widget.friendId);
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
    const summaryValueMaxChars = 14;
    final profile = _profile;
    if (profile == null) return const SizedBox.shrink();

    final birthDate = profile.birthDate == null || profile.birthDate!.isEmpty
        ? 'Não informado'
        : formatProfileDisplayDate(profile.birthDate!);

    final preferredPeriod = switch (profile.preferredPeriod) {
      'morning' => 'Manhã',
      'afternoon' => 'Tarde',
      'night' => 'Noite',
      _ => 'Não informado',
    };

    final objective = _formatObjective(profile.objective);
    final sex = _normalizeLabel(profile.sex);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _FriendProfilePreview(
            avatarUrl: profile.avatarUrl,
            frameId: profile.avatarFrameId,
            backgroundAssetPath: _backgroundAssetFromId(
              profile.avatarBackgroundId,
            ),
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
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        '${profile.friendCount} amigos',
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Amigos',
                  variant: AppButtonVariant.outline,
                  leadingIcon: Icons.people_alt_rounded,
                  onPressed: _isRemovingFriend ? null : _onRemoveFriendPressed,
                ),
                const SizedBox(height: AppSpacing.xl),
                _sectionTitle('Resumo'),
                const SizedBox(height: AppSpacing.sm),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth;
                    final spacing = AppSpacing.md;
                    final columns = maxWidth >= 720 ? 3 : 2;
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
                            value: _truncateWithEllipsis(
                              '${profile.streakDays} dias',
                              summaryValueMaxChars,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _metricCard(
                            icon: Icons.restaurant_menu_rounded,
                            iconColor: AppColors.socialMetricFavoriteDish,
                            label: 'Prato favorito',
                            value: _truncateWithEllipsis(
                              profile.favoriteDish?.trim().isNotEmpty == true
                                  ? profile.favoriteDish!
                                  : 'Sem registros',
                              summaryValueMaxChars,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _metricCard(
                            icon: Icons.schedule_rounded,
                            iconColor: AppColors.socialMetricPreferredPeriod,
                            label: 'Come mais de',
                            value: _truncateWithEllipsis(
                              preferredPeriod,
                              summaryValueMaxChars,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _metricCard(
                            icon: Icons.auto_awesome_rounded,
                            iconColor: AppColors.socialMetricXp,
                            label: 'Total de XP',
                            value: _truncateWithEllipsis(
                              '${profile.totalXp}',
                              summaryValueMaxChars,
                            ),
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
                  icon: Icons.cake_rounded,
                  iconColor: AppColors.socialInfoBirthDateBase,
                  label: 'Data de nascimento',
                  value: birthDate,
                ),
                const SizedBox(height: AppSpacing.md),
                _infoCard(
                  icon: Icons.person_rounded,
                  iconColor: AppColors.socialInfoSex,
                  label: 'Sexo',
                  value: sex,
                ),
                const SizedBox(height: AppSpacing.md),
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
        icon: Icons.error_outline_rounded,
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
    final raw = (value ?? '').trim().toLowerCase();
    if (raw.isEmpty) return 'Não informado';

    const labels = <String, String>{
      'lose_weight': 'Perder peso',
      'loseweight': 'Emagrecer',
      'losewight': 'Emagrecer',
      'weight_loss': 'Perder peso',
      'cut': 'Perder gordura',
      'maintain_weight': 'Manter peso',
      'maintenance': 'Manter peso',
      'maintain': 'Manter peso',
      'gain_weight': 'Ganhar peso',
      'weight_gain': 'Ganhar peso',
      'gainmass': 'Ganhar massa',
      'gain_mass': 'Ganhar massa',
      'bulk': 'Ganhar massa',
      'gain_muscle': 'Ganhar massa muscular',
      'muscle_gain': 'Ganhar massa muscular',
      'recomposition': 'Recomposição corporal',
    };

    return labels[raw] ?? _normalizeLabel(value);
  }

  String _truncateWithEllipsis(String value, int maxChars) {
    if (value.length <= maxChars) {
      return value;
    }
    return '${value.substring(0, maxChars)}...';
  }

  String? _backgroundAssetFromId(String? id) {
    switch (id?.trim()) {
      case 'sunset_orbit':
        return 'assets/images/avatar_backgrounds/sunset_orbit.png';
      case 'jungle_neon':
        return 'assets/images/avatar_backgrounds/jungle_neon.png';
      case 'aurora_grid':
        return 'assets/images/avatar_backgrounds/aurora_grid.png';
      case 'mango_sky':
        return 'assets/images/avatar_backgrounds/mango_sky.png';
      case 'mint_cloud':
        return 'assets/images/avatar_backgrounds/mint_cloud.png';
      case 'sky':
        return 'assets/images/avatar_backgrounds/sky.png';
      case 'pantano':
        return 'assets/images/avatar_backgrounds/pantano.png';
      default:
        return null;
    }
  }
}

class _FriendProfilePreview extends StatelessWidget {
  const _FriendProfilePreview({
    required this.avatarUrl,
    required this.frameId,
    required this.backgroundAssetPath,
    required this.name,
  });

  final String? avatarUrl;
  final String? frameId;
  final String? backgroundAssetPath;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 173,
      decoration: BoxDecoration(
        color: AppColors.homeProgressTrack,
        image: backgroundAssetPath == null
            ? null
            : DecorationImage(
                image: AssetImage(backgroundAssetPath!),
                fit: BoxFit.cover,
              ),
      ),
      child: Center(
        child: FramedAvatar(
          size: AppSpacing.huge * 3.4,
          avatarUrl: avatarUrl,
          frameId: frameId,
          fallbackText: name,
          backgroundColor: AppColors.surface,
        ),
      ),
    );
  }
}
