import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppAnchoredMenu extends StatefulWidget {
  const AppAnchoredMenu({
    super.key,
    required this.childBuilder,
    required this.menuBuilder,
    this.enabled = true,
    this.targetAnchor = Alignment.bottomRight,
    this.followerAnchor = Alignment.topRight,
    this.scaleAlignment = Alignment.topRight,
    this.offset = const Offset(0, 8),
  });

  final Widget Function(
    BuildContext context, {
    required bool isOpen,
    required VoidCallback toggle,
  })
  childBuilder;

  final Widget Function(
    BuildContext context, {
    required Future<void> Function() close,
  })
  menuBuilder;

  final bool enabled;
  final Alignment targetAnchor;
  final Alignment followerAnchor;
  final Alignment scaleAlignment;
  final Offset offset;

  @override
  State<AppAnchoredMenu> createState() => _AppAnchoredMenuState();
}

class _AppAnchoredMenuState extends State<AppAnchoredMenu>
    with SingleTickerProviderStateMixin {
  static const _openDuration = Duration(milliseconds: 220);
  static const _closeDuration = Duration(milliseconds: 160);
  static const _edgePadding = 8.0;

  final OverlayPortalController _portal = OverlayPortalController();
  late final AnimationController _animation;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final CurvedAnimation _curved;
  Animation<Offset> _slide = const AlwaysStoppedAnimation(Offset.zero);
  var _opensDown = true;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: _openDuration,
      reverseDuration: _closeDuration,
    );
    _curved = CurvedAnimation(
      parent: _animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _fade = _curved;
    _scale = Tween<double>(begin: 0.92, end: 1).animate(_curved);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(_curved);
  }

  @override
  void dispose() {
    _curved.dispose();
    _animation.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (!widget.enabled) return;
    if (_portal.isShowing) {
      await _close();
      return;
    }
    _opensDown = _hasRoomBelow();
    _slide = Tween<Offset>(
      begin: Offset(0, _opensDown ? -0.08 : 0.08),
      end: Offset.zero,
    ).animate(_curved);
    _portal.show();
    setState(() {});
    await _animation.forward();
  }

  Future<void> _close() async {
    if (!_portal.isShowing) return;
    await _animation.reverse();
    if (!mounted) return;
    _portal.hide();
    setState(() {});
  }

  bool _hasRoomBelow() {
    final targetRect = _targetRectInOverlay();
    final media = MediaQuery.maybeOf(context);
    if (targetRect == Rect.zero || media == null) return true;
    const estimatedMenuHeight = 196.0;
    final bottomLimit =
        media.size.height -
        math.max(media.viewPadding.bottom, media.viewInsets.bottom) -
        _edgePadding;
    return bottomLimit - targetRect.bottom >= estimatedMenuHeight;
  }

  Rect _targetRectInOverlay() {
    final overlay = Overlay.maybeOf(context);
    final targetBox = context.findRenderObject() as RenderBox?;
    final overlayBox = overlay?.context.findRenderObject() as RenderBox?;
    if (targetBox == null ||
        overlayBox == null ||
        !targetBox.hasSize ||
        !overlayBox.hasSize) {
      return Rect.zero;
    }
    final topLeft = overlayBox.globalToLocal(
      targetBox.localToGlobal(Offset.zero),
    );
    return topLeft & targetBox.size;
  }

  Alignment get _scaleAlignment {
    if (_opensDown) return widget.scaleAlignment;
    return Alignment(widget.scaleAlignment.x, -widget.scaleAlignment.y);
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (overlayContext) {
        final media = MediaQuery.of(overlayContext);
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _close,
              ),
            ),
            CustomSingleChildLayout(
              delegate: _AnchoredMenuLayoutDelegate(
                targetRect: _targetRectInOverlay(),
                overlaySize: media.size,
                viewPadding: media.viewPadding,
                viewInsets: media.viewInsets,
                targetAnchor: widget.targetAnchor,
                followerAnchor: widget.followerAnchor,
                offset: widget.offset,
                edgePadding: _edgePadding,
              ),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: ScaleTransition(
                    alignment: _scaleAlignment,
                    scale: _scale,
                    child: widget.menuBuilder(overlayContext, close: _close),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: widget.childBuilder(
        context,
        isOpen: _portal.isShowing,
        toggle: () {
          _toggle();
        },
      ),
    );
  }
}

class _AnchoredMenuLayoutDelegate extends SingleChildLayoutDelegate {
  _AnchoredMenuLayoutDelegate({
    required this.targetRect,
    required this.overlaySize,
    required this.viewPadding,
    required this.viewInsets,
    required this.targetAnchor,
    required this.followerAnchor,
    required this.offset,
    required this.edgePadding,
  });

  final Rect targetRect;
  final Size overlaySize;
  final EdgeInsets viewPadding;
  final EdgeInsets viewInsets;
  final Alignment targetAnchor;
  final Alignment followerAnchor;
  final Offset offset;
  final double edgePadding;

  double get _bottomInset => math.max(viewPadding.bottom, viewInsets.bottom);

  Offset _pointOnRect(Rect rect, Alignment alignment) {
    return Offset(
      rect.left + (alignment.x + 1) / 2 * rect.width,
      rect.top + (alignment.y + 1) / 2 * rect.height,
    );
  }

  double _clamp(double value, double min, double max) {
    if (max < min) return min;
    return value.clamp(min, max);
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final maxWidth = math.max(
      0.0,
      overlaySize.width -
          viewPadding.left -
          viewPadding.right -
          edgePadding * 2,
    );
    final maxHeight = math.max(
      0.0,
      overlaySize.height - viewPadding.top - _bottomInset - edgePadding * 2,
    );
    return BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final targetPoint = _pointOnRect(targetRect, targetAnchor);
    final followerPoint = Offset(
      (followerAnchor.x + 1) / 2 * childSize.width,
      (followerAnchor.y + 1) / 2 * childSize.height,
    );

    var dx = targetPoint.dx + offset.dx - followerPoint.dx;
    var dy = targetPoint.dy + offset.dy - followerPoint.dy;

    final minX = viewPadding.left + edgePadding;
    final maxX =
        overlaySize.width - viewPadding.right - edgePadding - childSize.width;
    final minY = viewPadding.top + edgePadding;
    final maxY =
        overlaySize.height - _bottomInset - edgePadding - childSize.height;

    if (dy > maxY) {
      dy = targetRect.top - offset.dy.abs() - childSize.height;
    } else if (dy < minY) {
      dy = targetRect.bottom + offset.dy.abs();
    }

    if (dx > maxX) {
      dx = targetRect.right - childSize.width;
    } else if (dx < minX) {
      dx = targetRect.left;
    }

    return Offset(_clamp(dx, minX, maxX), _clamp(dy, minY, maxY));
  }

  @override
  bool shouldRelayout(covariant _AnchoredMenuLayoutDelegate oldDelegate) {
    return targetRect != oldDelegate.targetRect ||
        overlaySize != oldDelegate.overlaySize ||
        viewPadding != oldDelegate.viewPadding ||
        viewInsets != oldDelegate.viewInsets ||
        targetAnchor != oldDelegate.targetAnchor ||
        followerAnchor != oldDelegate.followerAnchor ||
        offset != oldDelegate.offset ||
        edgePadding != oldDelegate.edgePadding;
  }
}
