import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_button.dart';
import 'app_floating_circle_button.dart';

/// One row in the expandable FAB menu (same pattern as Profile).
class AppExpandableFabAction {
  const AppExpandableFabAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.key,
    this.badgeCount,
    this.semanticLabel,
  });

  final Key? key;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final int? badgeCount;
  final String? semanticLabel;
}

/// Expandable circular FAB with stacked outline actions (Profile-style).
class AppExpandableFab extends StatefulWidget {
  const AppExpandableFab({
    super.key,
    required this.actions,
    this.closedIcon = Icons.more_horiz_rounded,
    this.openIcon = Icons.close_rounded,
    this.closedSemanticLabel = 'Abrir ações',
    this.openSemanticLabel = 'Fechar ações',
    this.menuWidth = 220,
    this.badgeCount,
  });

  /// Visual order from top to bottom (last item sits closest to the FAB).
  final List<AppExpandableFabAction> actions;
  final IconData closedIcon;
  final IconData openIcon;
  final String closedSemanticLabel;
  final String openSemanticLabel;
  final double menuWidth;
  final int? badgeCount;

  @override
  State<AppExpandableFab> createState() => _AppExpandableFabState();
}

class _AppExpandableFabState extends State<AppExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  var _expanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 240),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _close() {
    if (!_expanded) {
      return;
    }
    setState(() => _expanded = false);
    _controller.reverse();
  }

  Widget _animatedAction(AppExpandableFabAction action, int indexFromBottom) {
    final start = indexFromBottom * 0.08;
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: Curves.easeOutBack),
      reverseCurve: Curves.easeInCubic,
    );

    final badge = action.badgeCount ?? 0;
    final badgeLabel = badge <= 0 ? '' : (badge > 99 ? '99+' : '$badge');

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - animation.value)),
            child: Transform.scale(
              alignment: Alignment.bottomRight,
              scale: 0.92 + (0.08 * animation.value),
              child: child,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Semantics(
          button: true,
          label: action.semanticLabel ?? action.label,
          child: Stack(
            children: [
              // Reserve room for the badge: the menu lives inside a
              // SizeTransition (ClipRect), so anything outside gets cut off.
              Padding(
                padding: badgeLabel.isEmpty
                    ? EdgeInsets.zero
                    : const EdgeInsets.only(top: 8),
                child: AppButton(
                  key: action.key,
                  label: action.label,
                  onPressed: () {
                    _close();
                    action.onPressed();
                  },
                  variant: AppButtonVariant.outline,
                  leadingIcon: action.icon,
                  textStyle: AppTextStyles.buttonSmall,
                ),
              ),
              if (badgeLabel.isNotEmpty)
                Positioned(
                  key: ValueKey('expandable-fab-action-badge-$badgeLabel'),
                  top: 0,
                  right: 0,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: badgeLabel.length > 1 ? 5 : 0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brand900Variant,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.surface, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      badgeLabel,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.captionStrong.copyWith(
                        color: AppColors.surface,
                        height: 1,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = widget.actions;
    final count = actions.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Fixed width keeps SizeTransition from expanding to full screen
        // (its internal Align would otherwise center the menu away from the FAB).
        SizedBox(
          width: widget.menuWidth,
          child: SizeTransition(
            sizeFactor: CurvedAnimation(
              parent: _controller,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            ),
            axisAlignment: 1,
            child: ExcludeSemantics(
              excluding: !_expanded,
              child: IgnorePointer(
                ignoring: !_expanded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < count; i++)
                      _animatedAction(actions[i], count - 1 - i),
                  ],
                ),
              ),
            ),
          ),
        ),
        AppFloatingCircleButton(
          icon: _expanded ? widget.openIcon : widget.closedIcon,
          semanticLabel: _expanded
              ? widget.openSemanticLabel
              : widget.closedSemanticLabel,
          badgeCount: _expanded ? null : widget.badgeCount,
          onPressed: _toggle,
        ),
      ],
    );
  }
}
