import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_section_header.dart';
import '../widgets/social_create_group_sheet.dart';
import '../helpers/social_group_helpers.dart';
import '../models/social_group_models.dart';
import '../services/social_service.dart';
import '../widgets/social_activity_item.dart';
import '../widgets/social_ranking_item.dart';

class SocialGroupDetailPage extends StatefulWidget {
  const SocialGroupDetailPage({
    super.key,
    required this.groupId,
    this.initialDetail,
    SocialService? service,
  }) : _service = service ?? const SocialService();

  final String groupId;
  final SocialGroupDetail? initialDetail;
  final SocialService _service;

  @override
  State<SocialGroupDetailPage> createState() => _SocialGroupDetailPageState();
}

class _SocialGroupDetailPageState extends State<SocialGroupDetailPage> {
  SocialGroupDetail? _detail;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _detail = widget.initialDetail;
    _isLoading = _detail == null;
    if (_detail == null) {
      _loadDetail();
    }
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await widget._service.fetchGroup(widget.groupId);
      if (!mounted) {
        return;
      }

      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(child: _buildContent()),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.action500),
      );
    }

    if (_errorMessage != null || _detail == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage ?? 'Não foi possível carregar o grupo.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: 'Tentar novamente', onPressed: _loadDetail),
            ],
          ),
        ),
      );
    }

    final detail = _detail!;
    final group = detail.group;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.brand900Variant,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  group.name,
                  style: AppTextStyles.homeSectionTitle.copyWith(
                    color: AppColors.brand900Variant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: _openEditGroupSheet,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.settings_outlined,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.performanceCardBorder,
                width: 2,
              ),
              boxShadow: AppShadows.performanceCard,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: socialIconBackgroundColor(),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    socialGroupIconData(group.iconKey),
                    size: 30,
                    color: AppColors.action500,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: AppTextStyles.homeSectionTitle.copyWith(
                          color: AppColors.brand900Variant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        group.description,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _LabelPill(
                            label: group.competitionLabel,
                            foreground: AppColors.action500,
                            background: AppColors.missionsXpPill,
                          ),
                          _LabelPill(
                            label: group.durationDaysLabel,
                            foreground: AppColors.textMuted,
                            background: AppColors.surfaceAlt,
                          ),
                          _LabelPill(
                            label: group.remainingDaysLabel,
                            foreground: AppColors.missionsRewardGold,
                            background: AppColors.missionsGoldPill,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 56,
            child: AppButton(
              label: 'Convidar amigos',
              onPressed: () => _copyInviteCode(group.inviteCode),
              variant: AppButtonVariant.primary,
              leadingIcon: Icons.person_add_alt_rounded,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSectionHeader(
            title: 'Ranking',
            titleStyle: AppTextStyles.missionsSectionTitle.copyWith(
              color: AppColors.brand900Variant,
            ),
            trailing: const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.accent500,
              size: 22,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.performanceCardBorder,
                width: 2,
              ),
              boxShadow: AppShadows.performanceCard,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Column(
                children: [
                  for (final entry in detail.ranking)
                    SocialRankingItem(entry: entry),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSectionHeader(
            title: 'Atividade recente',
            titleStyle: AppTextStyles.missionsSectionTitle.copyWith(
              color: AppColors.brand900Variant,
            ),
            trailing: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.action500,
              size: 22,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Column(
            children: [
              for (final activity in detail.recentActivities) ...[
                SocialActivityItemWidget(activity: activity),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _copyInviteCode(String? inviteCode) async {
    if (inviteCode == null || inviteCode.isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: inviteCode));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Código $inviteCode copiado.')));
  }

  Future<void> _openEditGroupSheet() async {
    if (_detail == null) {
      return;
    }

    final result = await showModalBottomSheet<SocialGroupDetail>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SocialCreateGroupSheet(
        service: widget._service,
        existingGroup: _detail!.group,
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _detail = result;
    });
  }
}

class _LabelPill extends StatelessWidget {
  const _LabelPill({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTextStyles.captionStrong.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
