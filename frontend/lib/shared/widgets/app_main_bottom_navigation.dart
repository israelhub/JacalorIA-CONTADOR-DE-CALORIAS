import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../core/notifications/in_app_message_store.dart';
import '../theme/app_theme.dart';
import 'app_bottom_navigation.dart';
import 'app_nav_icons.dart';

enum AppMainBottomTab { social, home, missions, performance, workout }

class AppMainBottomNavigation extends StatefulWidget {
  const AppMainBottomNavigation({
    super.key,
    required this.activeTab,
    required this.onCenterActionTap,
    this.isMoreMenuOpen = false,
    this.onMoreTap,
    this.onPerformanceTap,
    this.onWorkoutTap,
    this.onStoreTap,
    this.onProfileTap,
    this.onNotificationsTap,
    this.onHomeTap,
    this.onMissionsTap,
    this.onSocialTap,
    this.onCardFocusLabTap,
  });

  final AppMainBottomTab activeTab;
  final bool isMoreMenuOpen;
  final VoidCallback onCenterActionTap;
  final VoidCallback? onMoreTap;
  final VoidCallback? onPerformanceTap;
  final VoidCallback? onWorkoutTap;
  final VoidCallback? onStoreTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onHomeTap;
  final VoidCallback? onMissionsTap;
  final VoidCallback? onSocialTap;
  final VoidCallback? onCardFocusLabTap;

  @override
  State<AppMainBottomNavigation> createState() =>
      _AppMainBottomNavigationState();
}

class _AppMainBottomNavigationState extends State<AppMainBottomNavigation>
    with SingleTickerProviderStateMixin {
  static const _openCurve = Cubic(0.22, 1, 0.36, 1);
  static const _closeCurve = Curves.easeInCubic;
  static const _scrimMaxOpacity = 0.32;
  static const _itemRisePx = 14.0;
  static const _moreNavGap = AppSpacing.sm;
  static const _navCardRadius = AppRadius.pill;
  static const _moreCardRadius = AppRadius.xl;

  late final AnimationController _moreController;
  final _scrimOverlay = OverlayPortalController();
  final InAppMessageStore _messageStore = InAppMessageStore.instance;
  final _navCardKey = GlobalKey(debugLabel: 'app-main-nav-card');
  final _moreCardKey = GlobalKey(debugLabel: 'app-main-more-card');

  bool get _isMoreActive {
    return widget.activeTab == AppMainBottomTab.missions ||
        widget.activeTab == AppMainBottomTab.workout;
  }

  void _onMessagesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  double _moreProgress(double value, {required bool closing}) {
    final curved = closing
        ? _closeCurve.transform(value)
        : _openCurve.transform(value);
    return curved.clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _messageStore.addListener(_onMessagesChanged);
    _moreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 280),
      value: widget.isMoreMenuOpen ? 1 : 0,
    );
    if (widget.isMoreMenuOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.isMoreMenuOpen) {
          return;
        }
        _scrimOverlay.show();
      });
    }
  }

  @override
  void didUpdateWidget(covariant AppMainBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMoreMenuOpen == oldWidget.isMoreMenuOpen) {
      return;
    }
    if (widget.isMoreMenuOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.isMoreMenuOpen) {
          return;
        }
        _scrimOverlay.show();
      });
      _moreController.forward();
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

  double _itemProgress(int indexFromBottom, double t) {
    final start = indexFromBottom * 0.045;
    final span = 1 - start;
    if (span <= 0) {
      return t;
    }
    return ((t - start) / span).clamp(0.0, 1.0);
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
        final t = _moreProgress(
          _moreController.value,
          closing: _moreController.status == AnimationStatus.reverse,
        );
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
        items: [
          _buildTabItem(
            onTap: widget.onPerformanceTap,
            child: AppBottomNavigationItem(
              label: 'Progresso',
              icon: AppNavIcons.performance(
                selected: widget.activeTab == AppMainBottomTab.performance,
              ),
              color: _tabColor(AppMainBottomTab.performance),
            ),
          ),
          _buildTabItem(
            onTap: widget.onHomeTap,
            child: AppBottomNavigationItem(
              label: 'Inicio',
              icon: AppNavIcons.home(
                selected: widget.activeTab == AppMainBottomTab.home,
              ),
              color: _tabColor(AppMainBottomTab.home),
            ),
          ),
          _buildTabItem(
            onTap: widget.onSocialTap,
            child: AppBottomNavigationItem(
              label: 'Social',
              icon: AppNavIcons.social(
                selected: widget.activeTab == AppMainBottomTab.social,
              ),
              color: _tabColor(AppMainBottomTab.social),
            ),
          ),
          _buildTabItem(
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
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _moreController,
              builder: (context, child) {
                if (_moreController.value == 0) {
                  return const SizedBox(width: double.infinity);
                }
                final t = _moreProgress(
                  _moreController.value,
                  closing: _moreController.status == AnimationStatus.reverse,
                );
                final fade = (t * 1.35).clamp(0.0, 1.0);
                return Padding(
                  padding: EdgeInsets.only(bottom: _moreNavGap * t),
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      heightFactor: t,
                      child: Opacity(opacity: fade, child: child),
                    ),
                  ),
                );
              },
              child: DecoratedBox(
                key: _moreCardKey,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(_moreCardRadius),
                  boxShadow: AppShadows.sm,
                  border: Border.all(
                    color: AppColors.borderBrandAlt,
                    width: 1.4,
                  ),
                ),
                child: _MoreDestinationsPanel(
                  activeTab: widget.activeTab,
                  controller: _moreController,
                  itemProgress: _itemProgress,
                  itemRisePx: _itemRisePx,
                  onMissionsTap: widget.onMissionsTap,
                  onWorkoutTap: widget.onWorkoutTap,
                  onNotificationsTap: widget.onNotificationsTap,
                  notificationsBadgeCount: _messageStore.unreadCount,
                  onStoreTap: widget.onStoreTap,
                  onProfileTap: widget.onProfileTap,
                  onCardFocusLabTap: widget.onCardFocusLabTap,
                ),
              ),
            ),
            _buildNavCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({required Widget child, VoidCallback? onTap}) {
    return _PressableMainNavItem(onTap: onTap, child: child);
  }

  Color _tabColor(AppMainBottomTab tab) {
    return widget.activeTab == tab ? AppColors.action500 : AppColors.divider;
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
    required this.controller,
    required this.itemProgress,
    required this.itemRisePx,
    this.onMissionsTap,
    this.onWorkoutTap,
    this.onNotificationsTap,
    this.notificationsBadgeCount = 0,
    this.onStoreTap,
    this.onProfileTap,
    this.onCardFocusLabTap,
  });

  final AppMainBottomTab activeTab;
  final AnimationController controller;
  final double Function(int indexFromBottom, double t) itemProgress;
  final double itemRisePx;
  final VoidCallback? onMissionsTap;
  final VoidCallback? onWorkoutTap;
  final VoidCallback? onNotificationsTap;
  final int notificationsBadgeCount;
  final VoidCallback? onStoreTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onCardFocusLabTap;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      if (onCardFocusLabTap != null)
        _MoreDestinationButton(
          label: 'Lab foco (temp)',
          icon: PhosphorIcons.swatches(PhosphorIconsStyle.regular),
          selected: false,
          onTap: onCardFocusLabTap,
        ),
      _MoreDestinationButton(
        label: 'Missões',
        icon: AppNavIcons.missions(
          selected: activeTab == AppMainBottomTab.missions,
        ),
        selected: activeTab == AppMainBottomTab.missions,
        onTap: onMissionsTap,
      ),
      _MoreDestinationButton(
        label: 'Treino',
        icon: AppNavIcons.workout(
          selected: activeTab == AppMainBottomTab.workout,
        ),
        selected: activeTab == AppMainBottomTab.workout,
        onTap: onWorkoutTap,
      ),
      _MoreDestinationButton(
        label: 'Perfil',
        icon: AppNavIcons.profile,
        selected: false,
        onTap: onProfileTap,
      ),
      _MoreDestinationButton(
        label: 'Loja',
        icon: AppNavIcons.store,
        selected: false,
        onTap: onStoreTap,
      ),
      _MoreDestinationButton(
        label: 'Notificações',
        icon: AppNavIcons.notifications,
        selected: false,
        badgeCount: notificationsBadgeCount,
        onTap: onNotificationsTap,
      ),
    ];

    return Padding(
      key: const ValueKey('app-more-destinations-panel'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final closing = controller.status == AnimationStatus.reverse;
          final t = (closing
                  ? Curves.easeInCubic.transform(controller.value)
                  : const Cubic(0.22, 1, 0.36, 1).transform(controller.value))
              .clamp(0.0, 1.0);
          final count = buttons.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < count; i++)
                Builder(
                  builder: (context) {
                    final progress = itemProgress(count - 1 - i, t);
                    final eased = Curves.easeOutCubic.transform(progress);
                    return Opacity(
                      opacity: eased,
                      child: Transform.translate(
                        offset: Offset(0, itemRisePx * (1 - eased)),
                        child: buttons[i],
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MoreDestinationButton extends StatelessWidget {
  const _MoreDestinationButton({
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
              PhosphorIcon(icon, size: 22, color: color),
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
  const _PressableMainNavItem({required this.child, required this.onTap});

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
