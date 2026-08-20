import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_floating_circle_button.dart';

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

class AppExpandableFab extends StatefulWidget {
  const AppExpandableFab({
    super.key,
    required this.actions,
    this.closedIcon = Icons.more_horiz_rounded,
    this.openIcon = Icons.close_rounded,
    this.closedSemanticLabel = 'Abrir ações',
    this.openSemanticLabel = 'Fechar ações',
    this.badgeCount,
  });

  /// Visual order from top to bottom (last item sits closest to the FAB).
  final List<AppExpandableFabAction> actions;
  final IconData closedIcon;
  final IconData openIcon;
  final String closedSemanticLabel;
  final String openSemanticLabel;
  final int? badgeCount;

  @override
  State<AppExpandableFab> createState() => _AppExpandableFabState();
}

class _AppExpandableFabState extends State<AppExpandableFab>
    with SingleTickerProviderStateMixin {
  static const _openCurve = Cubic(0.16, 1, 0.3, 1);

  final _overlayController = OverlayPortalController();
  late final AnimationController _controller;
  var _expanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_expanded) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    setState(() => _expanded = true);
    _overlayController.show();
    _controller.forward();
  }

  void _close() {
    if (!_expanded) {
      return;
    }
    setState(() => _expanded = false);
    _controller.reverse().whenComplete(() {
      if (!mounted || _expanded) {
        return;
      }
      _overlayController.hide();
    });
  }

  double _progressFor(int indexFromBottom) {
    final start = indexFromBottom * 0.07;
    final span = 1 - start;
    if (span <= 0) {
      return _controller.value;
    }
    final delayed = ((_controller.value - start) / span).clamp(0.0, 1.0);
    final curve = _controller.status == AnimationStatus.reverse
        ? Curves.easeInCubic
        : _openCurve;
    return curve.transform(delayed);
  }

  Widget _animatedAction(AppExpandableFabAction action, int indexFromBottom) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _progressFor(indexFromBottom);
        return IgnorePointer(
          ignoring: t < 0.05,
          child: Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(10 * (1 - t), 14 * (1 - t)),
              child: Transform.scale(
                alignment: Alignment.bottomRight,
                scale: 0.84 + (0.16 * t),
                child: child,
              ),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: _FabChoiceChip(
          action: action,
          onPressed: () {
            _close();
            action.onPressed();
          },
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context, OverlayChildLayoutInfo info) {
    if (info.childPaintTransform.determinant() == 0.0) {
      return const SizedBox.shrink();
    }

    final actions = widget.actions;
    final count = actions.length;
    final anchor = MatrixUtils.transformRect(
      info.childPaintTransform,
      Offset.zero & info.childSize,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _close,
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        Positioned(
          right: info.overlaySize.width - anchor.right,
          bottom: info.overlaySize.height - anchor.bottom,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < count; i++)
                _animatedAction(actions[i], count - 1 - i),
              GestureDetector(
                onTap: _toggle,
                child: SizedBox(
                  width: info.childSize.width,
                  height: info.childSize.height,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _overlayController,
      overlayLocation: OverlayChildLocation.rootOverlay,
      overlayChildBuilder: _buildOverlay,
      child: AppFloatingCircleButton(
        icon: _expanded ? widget.openIcon : widget.closedIcon,
        semanticLabel: _expanded
            ? widget.openSemanticLabel
            : widget.closedSemanticLabel,
        badgeCount: _expanded ? null : widget.badgeCount,
        onPressed: _toggle,
      ),
    );
  }
}

class _FabChoiceChip extends StatefulWidget {
  const _FabChoiceChip({
    required this.action,
    required this.onPressed,
  });

  final AppExpandableFabAction action;
  final VoidCallback onPressed;

  @override
  State<_FabChoiceChip> createState() => _FabChoiceChipState();
}

class _FabChoiceChipState extends State<_FabChoiceChip> {
  var _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }
    setState(() => _isPressed = value);
  }

  String get _badgeLabel {
    final count = widget.action.badgeCount ?? 0;
    if (count <= 0) {
      return '';
    }
    return count > 99 ? '99+' : '$count';
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    final badgeLabel = _badgeLabel;

    return Semantics(
      button: true,
      label: action.semanticLabel ?? action.label,
      child: GestureDetector(
        key: action.key,
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: widget.onPressed,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          offset: Offset(0, _isPressed ? 0.012 : 0),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutBack,
            scale: _isPressed ? 0.965 : 1,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.borderBrand),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.action500Shadow,
                        offset: Offset(0, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        action.label,
                        style: AppTextStyles.buttonSmall.copyWith(
                          color: AppColors.brand900Variant,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.action500,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          action.icon,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                if (badgeLabel.isNotEmpty)
                  Positioned(
                    key: ValueKey('expandable-fab-action-badge-$badgeLabel'),
                    top: -4,
                    right: -4,
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
      ),
    );
  }
}
