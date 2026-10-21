import 'package:flutter/material.dart';

import '../../core/notifications/in_app_message_store.dart';
import '../theme/app_theme.dart';
import 'app_bottom_navigation.dart';
import 'app_nav_icons.dart';

enum AppMainBottomTab { social, home, missions, performance, workout }

enum AppMainOverlayDestination {
  none,
  store,
  profile,
  notifications,
  reminders,
  support,
}

class AppMainBottomNavigation extends StatefulWidget {
  const AppMainBottomNavigation({
    super.key,
    required this.activeTab,
    required this.onCenterActionTap,
    this.overlayDestination = AppMainOverlayDestination.none,
    this.isMoreMenuOpen = false,
    this.onMoreTap,
    this.onPerformanceTap,
    this.onWorkoutTap,
    this.onStoreTap,
    this.onProfileTap,
    this.onNotificationsTap,
    this.onRemindersTap,
    this.onSupportTap,
    this.onHomeTap,
    this.onMissionsTap,
    this.onSocialTap,
    this.performanceTabKey,
    this.homeTabKey,
    this.socialTabKey,
    this.moreTabKey,
    this.missionsDestinationKey,
    this.workoutDestinationKey,
    this.profileDestinationKey,
    this.remindersDestinationKey,
    this.notificationsDestinationKey,
    this.morePanelKey,
    this.moreBundleKey,
    this.centerActionKey,
    this.suppressMoreScrim = false,
  });

  final AppMainBottomTab activeTab;
  final AppMainOverlayDestination overlayDestination;
  final bool isMoreMenuOpen;
  final VoidCallback onCenterActionTap;
  final VoidCallback? onMoreTap;
  final VoidCallback? onPerformanceTap;
  final VoidCallback? onWorkoutTap;
  final VoidCallback? onStoreTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onRemindersTap;
  final VoidCallback? onSupportTap;
  final VoidCallback? onHomeTap;
  final VoidCallback? onMissionsTap;
  final VoidCallback? onSocialTap;
  final Key? performanceTabKey;
  final Key? homeTabKey;
  final Key? socialTabKey;
  final Key? moreTabKey;
  final Key? missionsDestinationKey;
  final Key? workoutDestinationKey;
  final Key? profileDestinationKey;
  final Key? remindersDestinationKey;
  final Key? notificationsDestinationKey;
  final Key? morePanelKey;
  final Key? moreBundleKey;
  final Key? centerActionKey;
  final bool suppressMoreScrim;

  @override
  State<AppMainBottomNavigation> createState() =>
      _AppMainBottomNavigationState();
}

class _AppMainBottomNavigationState extends State<AppMainBottomNavigation>
    with SingleTickerProviderStateMixin {
  static const _openCurve = Curves.easeOutCubic;
  static const _scrimMaxOpacity = 0.32;
  static const _moreNavGap = AppSpacing.sm;
  static const _navCardRadius = AppRadius.pill;
  static const _moreCardRadius = AppRadius.xl;
  static const _openDuration = Duration(milliseconds: 600);
  static const _closeDuration = Duration(milliseconds: 450);

  late final AnimationController _moreController;
  final _scrimOverlay = OverlayPortalController();
  final InAppMessageStore _messageStore = InAppMessageStore.instance;
  final _navCardKey = GlobalKey(debugLabel: 'app-main-nav-card');
  late final GlobalKey _moreCardKey;

  bool get _hasOverlayDestination {
    return widget.overlayDestination != AppMainOverlayDestination.none;
  }

  bool get _isMoreActive {
    if (_hasOverlayDestination) {
      return true;
    }
    return widget.activeTab == AppMainBottomTab.missions ||
        widget.activeTab == AppMainBottomTab.workout;
  }

  bool _isSwipeTabSelected(AppMainBottomTab tab) {
    return !_hasOverlayDestination && widget.activeTab == tab;
  }

  void _onMessagesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  double _moreProgress(double value) {
    return _openCurve.transform(value).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _moreCardKey = widget.morePanelKey is GlobalKey
        ? widget.morePanelKey! as GlobalKey
        : GlobalKey(debugLabel: 'app-main-more-card');
    _messageStore.addListener(_onMessagesChanged);
    _moreController = AnimationController(
      vsync: this,
      duration: _openDuration,
      reverseDuration: _closeDuration,
      value: widget.isMoreMenuOpen ? 1 : 0,
    );
    if (widget.isMoreMenuOpen && !widget.suppressMoreScrim) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.isMoreMenuOpen || widget.suppressMoreScrim) {
          return;
        }
        _scrimOverlay.show();
      });
    }
  }

  @override
  void didUpdateWidget(covariant AppMainBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.suppressMoreScrim && _scrimOverlay.isShowing) {
      _scrimOverlay.hide();
    }
    if (widget.isMoreMenuOpen == oldWidget.isMoreMenuOpen &&
        widget.suppressMoreScrim == oldWidget.suppressMoreScrim) {
      return;
    }
    if (widget.isMoreMenuOpen) {
      if (!widget.suppressMoreScrim) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !widget.isMoreMenuOpen || widget.suppressMoreScrim) {
            return;
          }
          _scrimOverlay.show();
        });
      } else if (_scrimOverlay.isShowing) {
        _scrimOverlay.hide();
      }
      if (widget.isMoreMenuOpen != oldWidget.isMoreMenuOpen) {
        _moreController.forward();
      }
    } else {
      _moreController.reverse().whenComplete(() {
        if (!mounted || widget.isMoreMenuOpen) {
          return;
        }
        _scrimOverlay.hide();
      });
    }
  }

  @override
  void dispose() {
    _messageStore.removeListener(_onMessagesChanged);
    _moreController.dispose();
    super.dispose();
  }

  RRect? _cardRRect(GlobalKey key, double radius) {
    final context = key.currentContext;
    if (context == null) {
      return null;
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) {
      return null;
    }
    final offset = box.localToGlobal(Offset.zero);
    return RRect.fromRectAndRadius(
      offset & box.size,
      Radius.circular(radius),
    );
  }

  Widget _buildScrim(BuildContext context, OverlayChildLayoutInfo info) {
    if (info.childPaintTransform.determinant() == 0.0) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _moreController,
      builder: (context, _) {
        final t = _moreProgress(_moreController.value);
        final navHole = _cardRRect(_navCardKey, _navCardRadius);
        final moreHole = t > 0 ? _cardRRect(_moreCardKey, _moreCardRadius) : null;
        final holes = <RRect>[
          if (navHole != null) navHole,
          if (moreHole != null) moreHole,
        ];

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.deferToChild,
                onTap: widget.onMoreTap,
                child: CustomPaint(
                  painter: _ScrimWithHolesPainter(
                    color: Colors.black.withValues(alpha: _scrimMaxOpacity * t),
                    holes: holes,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMorePanel({required double progress}) {
    if (progress <= 0) {
      return const SizedBox(width: double.infinity);
    }

    final panel = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(_moreCardRadius),
        boxShadow: AppShadows.sm,
        border: Border.all(color: AppColors.borderBrandAlt, width: 1.4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_moreCardRadius),
        child: IgnorePointer(
          ignoring: progress < 0.55,
          child: _MoreDestinationsPanel(
            activeTab: widget.activeTab,
            overlayDestination: widget.overlayDestination,
            onMissionsTap: widget.onMissionsTap,
            onWorkoutTap: widget.onWorkoutTap,
            onNotificationsTap: widget.onNotificationsTap,
            notificationsBadgeCount: _messageStore.unreadCount,
            onStoreTap: widget.onStoreTap,
            onProfileTap: widget.onProfileTap,
            onRemindersTap: widget.onRemindersTap,
            onSupportTap: widget.onSupportTap,
            missionsDestinationKey: widget.missionsDestinationKey,
            workoutDestinationKey: widget.workoutDestinationKey,
            profileDestinationKey: widget.profileDestinationKey,
            remindersDestinationKey: widget.remindersDestinationKey,
            notificationsDestinationKey: widget.notificationsDestinationKey,
          ),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: _moreNavGap * progress),
      child: ClipRect(
        child: Align(
          key: _moreCardKey,
          alignment: Alignment.bottomCenter,
          heightFactor: progress,
          child: panel,
        ),
      ),
    );
  }

  Widget _buildNavCard() {
    return DecoratedBox(
      key: _navCardKey,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(_navCardRadius),
        boxShadow: AppShadows.sm,
        border: Border.all(color: AppColors.borderBrandAlt, width: 1.4),
      ),
      child: AppBottomNavigation(
        includeBottomSafeArea: false,
        showTopBorder: false,
        backgroundColor: Colors.transparent,
        contentHorizontalPadding: AppSpacing.sm,
        centerActionKey:
            widget.centerActionKey ??
            const ValueKey('app-bottom-nav-center-action'),
        items: [
          _buildTabItem(
            key: widget.performanceTabKey,
            onTap: widget.onPerformanceTap,
            child: AppBottomNavigationItem(
              label: 'Progresso',
              icon: AppNavIcons.performance(
                selected: _isSwipeTabSelected(AppMainBottomTab.performance),
              ),
              color: _tabColor(AppMainBottomTab.performance),
            ),
          ),
          _buildTabItem(
            key: widget.homeTabKey,
            onTap: widget.onHomeTap,
            child: AppBottomNavigationItem(
              label: 'Inicio',
              icon: AppNavIcons.home(
                selected: _isSwipeTabSelected(AppMainBottomTab.home),
              ),
              color: _tabColor(AppMainBottomTab.home),
            ),
          ),
          _buildTabItem(
            key: widget.socialTabKey,
            onTap: widget.onSocialTap,
            child: AppBottomNavigationItem(
              label: 'Social',
              icon: AppNavIcons.social(
                selected: _isSwipeTabSelected(AppMainBottomTab.social),
              ),
              color: _tabColor(AppMainBottomTab.social),
            ),
          ),
          _buildTabItem(
            key: widget.moreTabKey,
            onTap: widget.onMoreTap,
            child: AppBottomNavigationItem(
              label: 'Mais',
              icon: AppNavIcons.more(selected: false),
              color: _isMoreActive || widget.isMoreMenuOpen
                  ? AppColors.action500
                  : AppColors.divider,
            ),
          ),
        ],
        onCenterActionTap: widget.onCenterActionTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;

    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _scrimOverlay,
      overlayLocation: OverlayChildLocation.rootOverlay,
      overlayChildBuilder: _buildScrim,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          appBottomNavHorizontalInset,
          0,
          appBottomNavHorizontalInset,
          safeBottom + AppSpacing.sm,
        ),
        child: Column(
          key: widget.moreBundleKey,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _moreController,
              builder: (context, _) => _buildMorePanel(
                progress: _moreProgress(_moreController.value),
              ),
            ),
            _buildNavCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    Key? key,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return _PressableMainNavItem(key: key, onTap: onTap, child: child);
  }

  Color _tabColor(AppMainBottomTab tab) {
    return _isSwipeTabSelected(tab) ? AppColors.action500 : AppColors.divider;
  }
}

class _ScrimWithHolesPainter extends CustomPainter {
  const _ScrimWithHolesPainter({required this.color, required this.holes});

  final Color color;
  final List<RRect> holes;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = color;
    if (holes.isEmpty) {
      canvas.drawRect(Offset.zero & size, scrim);
      return;
    }

    final path = Path()..addRect(Offset.zero & size);
    for (final hole in holes) {
      path.addRRect(hole);
    }
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, scrim);
  }

  @override
  bool shouldRepaint(covariant _ScrimWithHolesPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.holes != holes;
  }

  @override
  bool hitTest(Offset position) {
    for (final hole in holes) {
      if (hole.contains(position)) {
        return false;
      }
    }
    return true;
  }
}

class _MoreDestinationsPanel extends StatelessWidget {
  const _MoreDestinationsPanel({
    required this.activeTab,
    required this.overlayDestination,
    this.onMissionsTap,
    this.onWorkoutTap,
    this.onNotificationsTap,
    this.notificationsBadgeCount = 0,
    this.onStoreTap,
    this.onProfileTap,
    this.onRemindersTap,
    this.onSupportTap,
    this.missionsDestinationKey,
    this.workoutDestinationKey,
    this.profileDestinationKey,
    this.remindersDestinationKey,
    this.notificationsDestinationKey,
  });

  final AppMainBottomTab activeTab;
  final AppMainOverlayDestination overlayDestination;
  final VoidCallback? onMissionsTap;
  final VoidCallback? onWorkoutTap;
  final VoidCallback? onNotificationsTap;
  final int notificationsBadgeCount;
  final VoidCallback? onStoreTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onRemindersTap;
  final VoidCallback? onSupportTap;
  final Key? missionsDestinationKey;
  final Key? workoutDestinationKey;
  final Key? profileDestinationKey;
  final Key? remindersDestinationKey;
  final Key? notificationsDestinationKey;

  bool get _hasOverlay {
    return overlayDestination != AppMainOverlayDestination.none;
  }

  bool _isTabSelected(AppMainBottomTab tab) {
    return !_hasOverlay && activeTab == tab;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('app-more-destinations-panel'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MoreDestinationButton(
            key: missionsDestinationKey,
            label: 'Missões',
            icon: AppNavIcons.missions(
              selected: _isTabSelected(AppMainBottomTab.missions),
            ),
            selected: _isTabSelected(AppMainBottomTab.missions),
            onTap: onMissionsTap,
          ),
          _MoreDestinationButton(
            key: workoutDestinationKey,
            label: 'Treino',
            icon: AppNavIcons.workout(
              selected: _isTabSelected(AppMainBottomTab.workout),
            ),
            selected: _isTabSelected(AppMainBottomTab.workout),
            onTap: onWorkoutTap,
          ),
          _MoreDestinationButton(
            key: profileDestinationKey,
            label: 'Perfil',
            icon: AppNavIcons.profile,
            selected: overlayDestination == AppMainOverlayDestination.profile,
            onTap: onProfileTap,
          ),
          _MoreDestinationButton(
            label: 'Loja',
            icon: AppNavIcons.store,
            selected: overlayDestination == AppMainOverlayDestination.store,
            onTap: onStoreTap,
          ),
          _MoreDestinationButton(
            key: notificationsDestinationKey,
            label: 'Notificações',
            icon: AppNavIcons.notifications,
            selected:
                overlayDestination == AppMainOverlayDestination.notifications,
            badgeCount: notificationsBadgeCount,
            onTap: onNotificationsTap,
          ),
          _MoreDestinationButton(
            key: remindersDestinationKey,
            label: 'Lembretes de refeição',
            icon: Icons.notifications_active_outlined,
            selected: overlayDestination == AppMainOverlayDestination.reminders,
            onTap: onRemindersTap,
          ),
          _MoreDestinationButton(
            label: 'Suporte',
            icon: Icons.support_agent_rounded,
            selected: overlayDestination == AppMainOverlayDestination.support,
            onTap: onSupportTap,
          ),
        ],
      ),
    );
  }
}

class _MoreDestinationButton extends StatelessWidget {
  const _MoreDestinationButton({
    super.key,
    required this.label,
    required this.selected,
    required this.icon,
    this.badgeCount = 0,
    this.onTap,
  });

  final String label;
  final bool selected;
  final IconData icon;
  final int badgeCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.action500 : AppColors.brand900Variant;
    return Material(
      color: selected ? AppColors.missionsXpPill : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.homeAction.copyWith(color: color),
                ),
              ),
              if (badgeCount > 0)
                Container(
                  key: ValueKey('more-destination-badge-$badgeCount'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.action500,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: AppTextStyles.micro.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PressableMainNavItem extends StatefulWidget {
  const _PressableMainNavItem({
    super.key,
    required this.child,
    required this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_PressableMainNavItem> createState() => _PressableMainNavItemState();
}

class _PressableMainNavItemState extends State<_PressableMainNavItem> {
  bool _isPressed = false;
  bool _isHovered = false;

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }
    setState(() {
      _isPressed = value;
    });
  }

  void _setHovered(bool value) {
    if (_isHovered == value) {
      return;
    }
    setState(() {
      _isHovered = value;
    });
  }

  Future<void> _handleTap() async {
    if (widget.onTap == null) {
      return;
    }
    _setPressed(true);
    widget.onTap!.call();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (!mounted) {
      return;
    }
    _setPressed(false);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) {},
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _isPressed
              ? 0.94
              : (_isHovered && widget.onTap != null ? 1.05 : 1),
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
