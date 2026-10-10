import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_back_page_header.dart';

class AppExpandableHeaderMenuAction {
  const AppExpandableHeaderMenuAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final VoidCallback onPressed;
}

class AppExpandableHeaderMenu extends StatefulWidget {
  const AppExpandableHeaderMenu({
    super.key,
    required this.actions,
    this.tooltip = 'Mais opções',
    this.closedIcon = Icons.more_horiz_rounded,
    this.openIcon = Icons.close_rounded,
    this.showShadow = false,
  });

  final List<AppExpandableHeaderMenuAction> actions;
  final String tooltip;
  final IconData closedIcon;
  final IconData openIcon;
  final bool showShadow;

  @override
  State<AppExpandableHeaderMenu> createState() =>
      _AppExpandableHeaderMenuState();
}

class _AppExpandableHeaderMenuState extends State<AppExpandableHeaderMenu>
    with SingleTickerProviderStateMixin {
  static const _openCurve = Cubic(0.16, 1, 0.3, 1);
  static const double _chipSize = AppBackPageHeaderBar.chipHeight;
  static const double _itemHeight = 44;
  static const double _iconSize = 20;
  static const double _scrimMaxOpacity = 0.32;

  final _overlayController = OverlayPortalController();
  late final AnimationController _controller;
  var _expanded = false;

  double get _panelHeight =>
      _chipSize + (widget.actions.length * _itemHeight) + AppSpacing.sm;

  double _panelWidthFor(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final labelStyle = AppTextStyles.bodyMedium.copyWith(
      fontWeight: FontWeight.w600,
    );
    var maxLabelWidth = 0.0;
    var hasIcon = false;

    for (final action in widget.actions) {
      if (action.icon != null) {
        hasIcon = true;
      }
      final painter = TextPainter(
        text: TextSpan(text: action.label, style: labelStyle),
        maxLines: 1,
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      maxLabelWidth = math.max(maxLabelWidth, painter.width);
    }

    final contentWidth =
        AppSpacing.md * 2 +
        AppSpacing.sm * 2 +
        (hasIcon ? _iconSize + AppSpacing.sm : 0) +
        maxLabelWidth +
        AppSpacing.md;

    return math.max(_chipSize, contentWidth);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 200),
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

  void _select(AppExpandableHeaderMenuAction action) {
    _close();
    action.onPressed();
  }

  Widget _buildChipButton({required bool expanded}) {
    final chip = Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _toggle,
        child: SizedBox(
          width: _chipSize,
          height: _chipSize,
          child: Icon(
            expanded ? widget.openIcon : widget.closedIcon,
            color: AppColors.brand900Variant,
            size: 22,
          ),
        ),
      ),
    );

    return Tooltip(
      message: widget.tooltip,
      child: widget.showShadow
          ? DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: AppShadows.sm,
              ),
              child: chip,
            )
          : chip,
    );
  }

  Widget _buildOverlay(BuildContext context, OverlayChildLayoutInfo info) {
    if (info.childPaintTransform.determinant() == 0.0) {
      return const SizedBox.shrink();
    }

    final anchor = MatrixUtils.transformRect(
      info.childPaintTransform,
      Offset.zero & info.childSize,
    );
    final panelWidth = _panelWidthFor(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final raw = _controller.status == AnimationStatus.reverse
            ? Curves.easeInCubic.transform(_controller.value)
            : _openCurve.transform(_controller.value);
        final t = raw.clamp(0.0, 1.0);
        final width = lerpDouble(_chipSize, panelWidth, t)!;
        final height = lerpDouble(_chipSize, _panelHeight, t)!;
        final radius = lerpDouble(_chipSize / 2, AppRadius.lg, t)!;
        final contentOpacity = ((t - 0.35) / 0.65).clamp(0.0, 1.0);

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _close,
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: _scrimMaxOpacity * t),
                ),
              ),
            ),
            Positioned(
              top: anchor.top,
              right: info.overlaySize.width - anchor.right,
              child: Material(
                color: AppColors.surface,
                elevation: 2 * t,
                shadowColor: Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(radius),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: width,
                  height: height,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: _chipSize,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: _toggle,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: SizedBox(
                              width: _chipSize,
                              height: _chipSize,
                              child: Icon(
                                t > 0.5
                                    ? widget.openIcon
                                    : widget.closedIcon,
                                color: AppColors.brand900Variant,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Opacity(
                          opacity: contentOpacity,
                          child: IgnorePointer(
                            ignoring: contentOpacity < 0.6,
                            child: ListView(
                              padding: const EdgeInsets.only(
                                left: AppSpacing.md,
                                right: AppSpacing.md,
                                bottom: AppSpacing.xs,
                              ),
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                for (final action in widget.actions)
                                  SizedBox(
                                    height: _itemHeight,
                                    width: double.infinity,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.md,
                                      ),
                                      onTap: () => _select(action),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                        ),
                                        child: Row(
                                          children: [
                                            if (action.icon != null) ...[
                                              Icon(
                                                action.icon,
                                                size: _iconSize,
                                                color:
                                                    action.color ??
                                                    AppColors.brand900Variant,
                                              ),
                                              const SizedBox(
                                                width: AppSpacing.sm,
                                              ),
                                            ] else if (widget.actions.any(
                                              (item) => item.icon != null,
                                            )) ...[
                                              const SizedBox(
                                                width: _iconSize + AppSpacing.sm,
                                              ),
                                            ],
                                            Flexible(
                                              child: Text(
                                                action.label,
                                                maxLines: 1,
                                                softWrap: false,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTextStyles.bodyMedium
                                                    .copyWith(
                                                      color:
                                                          action.color ??
                                                          AppColors
                                                              .brand900Variant,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _overlayController,
      overlayLocation: OverlayChildLocation.rootOverlay,
      overlayChildBuilder: _buildOverlay,
      child: Opacity(
        opacity: _expanded ? 0 : 1,
        child: _buildChipButton(expanded: false),
      ),
    );
  }
}
