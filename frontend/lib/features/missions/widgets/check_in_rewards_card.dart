import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../avatar_frames/models/avatar_background_catalog.dart';
import '../../avatar_frames/models/avatar_frame_catalog.dart';
import '../models/missions_overview.dart';

class CheckInRewardsCard extends StatefulWidget {
  const CheckInRewardsCard({
    super.key,
    required this.checkIn,
    required this.onClaim,
    this.isClaiming = false,
  });

  final CheckInInfo checkIn;
  final VoidCallback? onClaim;
  final bool isClaiming;

  @override
  State<CheckInRewardsCard> createState() => _CheckInRewardsCardState();
}

class _CheckInRewardsCardState extends State<CheckInRewardsCard> {
  final ScrollController _daysController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  @override
  void didUpdateWidget(covariant CheckInRewardsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.checkIn.todayDayKey != widget.checkIn.todayDayKey ||
        oldWidget.checkIn.days.length != widget.checkIn.days.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
    }
  }

  @override
  void dispose() {
    _daysController.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    if (!_daysController.hasClients) {
      return;
    }
    final days = widget.checkIn.days;
    final index = days.indexWhere(
      (day) => day.dayKey == widget.checkIn.todayDayKey,
    );
    if (index < 0) {
      return;
    }

    const itemExtent = 92.0;
    final target = (index * itemExtent) - 24;
    _daysController.animateTo(
      target.clamp(0.0, _daysController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkIn = widget.checkIn;
    final claimEnabled =
        checkIn.canClaimToday && !widget.isClaiming && widget.onClaim != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          checkIn.title,
          style: AppTextStyles.missionsSectionTitle.copyWith(
            color: AppColors.brand900Variant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(0, 18, 0, 16),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.performanceCardBorder, width: 2),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  checkIn.subtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.brand900Variant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 76,
                child: ListView.separated(
                  controller: _daysController,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: checkIn.days.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    return _CheckInDayTile(day: checkIn.days[index]);
                  },
                ),
              ),
              if (!checkIn.claimedToday) ...<Widget>[
                const SizedBox(height: AppSpacing.xl),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AppButton(
                    label: widget.isClaiming
                        ? 'Recebendo...'
                        : 'Receber recompensa',
                    onPressed: claimEnabled ? widget.onClaim : null,
                  ),
                ),
              ] else ...<Widget>[
                const SizedBox(height: AppSpacing.xl),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      'A próxima recompensa ficará disponível amanhã',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckInDayTile extends StatelessWidget {
  const _CheckInDayTile({required this.day});

  final CheckInDayItem day;

  static const ColorFilter _greyFilter = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 40,
    0.2126, 0.7152, 0.0722, 0, 40,
    0.2126, 0.7152, 0.0722, 0, 40,
    0, 0, 0, 0.85, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final isToday = day.status == CheckInDayStatus.claimable;
    final isClaimed = day.status == CheckInDayStatus.claimed;
    final muted = day.status == CheckInDayStatus.missed;

    final labelColor = isClaimed
        ? AppColors.action500
        : isToday
        ? const Color(0xFF0B7BB8)
        : muted
        ? AppColors.textTertiary
        : AppColors.textSecondary;

    final rewardIcon = _withSilhouetteShadow();

    return SizedBox(
      width: 86,
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: <Widget>[
                if (muted)
                  ColorFiltered(
                    colorFilter: _greyFilter,
                    child: rewardIcon,
                  )
                else
                  rewardIcon,
                if (isClaimed)
                  const Positioned(
                    right: 0,
                    top: -2,
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: AppColors.action500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            day.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: labelColor,
              fontWeight: isClaimed || isToday
                  ? FontWeight.w800
                  : FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _withSilhouetteShadow() {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: <Widget>[
        Transform.translate(
          offset: const Offset(0, 3),
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Color(0x401E513E),
              BlendMode.srcIn,
            ),
            child: _rewardVisual(),
          ),
        ),
        _rewardVisual(),
      ],
    );
  }

  Widget _rewardVisual() {
    final cosmeticKey = _cosmeticItemKey();
    switch (day.primaryKind) {
      case CheckInRewardKind.blocker:
        return const AppSvgIcon.blocker(size: 52);
      case CheckInRewardKind.frame:
        final path = AvatarFrameCatalog.byId(cosmeticKey)?.assetPath;
        if (path != null) {
          return Image.asset(
            path,
            width: 54,
            height: 54,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          );
        }
        return Icon(
          Icons.auto_awesome_rounded,
          size: 44,
          color: AppColors.missionsChallenge,
        );
      case CheckInRewardKind.background:
        final path = AvatarBackgroundCatalog.byId(cosmeticKey)?.assetPath;
        if (path != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              path,
              width: 54,
              height: 54,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
          );
        }
        return Icon(
          Icons.wallpaper_rounded,
          size: 44,
          color: AppColors.socialInfoBirthDateFilling,
        );
      case CheckInRewardKind.gold:
        return const AppSvgIcon.gold(size: 52);
    }
  }

  String? _cosmeticItemKey() {
    for (final reward in day.rewards) {
      if (reward.kind == day.primaryKind && reward.itemKey.isNotEmpty) {
        return reward.itemKey;
      }
    }
    return null;
  }
}
