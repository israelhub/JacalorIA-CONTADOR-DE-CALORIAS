import 'package:flutter/material.dart';

class PreferVerticalPageView extends StatefulWidget {
  const PreferVerticalPageView({
    super.key,
    required this.controller,
    required this.onPageChanged,
    required this.children,
  });

  final PageController controller;
  final ValueChanged<int> onPageChanged;
  final List<Widget> children;

  @override
  State<PreferVerticalPageView> createState() => _PreferVerticalPageViewState();
}

class _PreferVerticalPageViewState extends State<PreferVerticalPageView> {
  static const double _axisDecideSlop = 10;
  static const double _horizontalDominance = 1.35;

  final ValueNotifier<bool> _lockSwipe = ValueNotifier<bool>(false);
  Offset? _pointerStart;
  int? _activePointer;
  bool _axisDecided = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_enableInnerScroll);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_enableInnerScroll);
    _lockSwipe.dispose();
    super.dispose();
  }

  void _enableInnerScroll() {
    if (!widget.controller.hasClients) {
      return;
    }
    widget.controller.position.context.setIgnorePointer(false);
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_activePointer != null) {
      return;
    }
    _activePointer = event.pointer;
    _pointerStart = event.position;
    _axisDecided = false;
    if (_lockSwipe.value) {
      _lockSwipe.value = false;
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer ||
        _axisDecided ||
        _pointerStart == null) {
      return;
    }

    final delta = event.position - _pointerStart!;
    if (delta.distance < _axisDecideSlop) {
      return;
    }

    _axisDecided = true;
    final isHorizontal =
        delta.dx.abs() > delta.dy.abs() * _horizontalDominance;
    if (!isHorizontal && !_lockSwipe.value) {
      _lockSwipe.value = true;
    }
  }

  void _onPointerEnd(PointerEvent event) {
    if (event.pointer != _activePointer) {
      return;
    }
    _activePointer = null;
    _pointerStart = null;
    _axisDecided = false;
    if (_lockSwipe.value) {
      _lockSwipe.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerEnd,
      onPointerCancel: _onPointerEnd,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.depth == 0) {
            _enableInnerScroll();
          }
          return false;
        },
        child: ValueListenableBuilder<bool>(
          valueListenable: _lockSwipe,
          builder: (context, lockSwipe, _) {
            return PageView(
              controller: widget.controller,
              onPageChanged: widget.onPageChanged,
              physics: lockSwipe
                  ? const NeverScrollableScrollPhysics()
                  : const _TabPageScrollPhysics(),
              children: widget.children,
            );
          },
        ),
      ),
    );
  }
}

class _TabPageScrollPhysics extends PageScrollPhysics {
  const _TabPageScrollPhysics({super.parent});

  @override
  _TabPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _TabPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double get dragStartDistanceMotionThreshold => 24;

  @override
  double get minFlingVelocity => 350;
}
