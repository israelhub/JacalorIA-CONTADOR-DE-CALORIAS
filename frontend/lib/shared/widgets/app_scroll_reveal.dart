import 'package:flutter/material.dart';

class AppScrollReveal extends StatefulWidget {
  const AppScrollReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<AppScrollReveal> createState() => _AppScrollRevealState();
}

class _AppScrollRevealState extends State<AppScrollReveal> {
  bool _measured = false;
  bool _armed = false;
  bool _visible = true;
  bool _animate = false;
  bool _pageActive = false;
  bool _enteredOnce = false;
  int _measureRetries = 0;
  int _revealGen = 0;
  ScrollPosition? _verticalPosition;
  ScrollPosition? _horizontalPosition;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bindPosition(
      current: _verticalPosition,
      next: Scrollable.maybeOf(context)?.position,
      assign: (position) => _verticalPosition = position,
    );
    _bindPosition(
      current: _horizontalPosition,
      next: Scrollable.maybeOf(context, axis: Axis.horizontal)?.position,
      assign: (position) => _horizontalPosition = position,
      onScroll: _onPageScroll,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  void _bindPosition({
    required ScrollPosition? current,
    required ScrollPosition? next,
    required void Function(ScrollPosition? position) assign,
    VoidCallback? onScroll,
  }) {
    if (identical(current, next)) {
      return;
    }
    current?.removeListener(onScroll ?? _checkVisibility);
    assign(next);
    next?.addListener(onScroll ?? _checkVisibility);
  }

  void _onPageScroll() {
    if (_enteredOnce) {
      return;
    }
    _checkVisibility();
  }

  @override
  void dispose() {
    _verticalPosition?.removeListener(_checkVisibility);
    _horizontalPosition?.removeListener(_onPageScroll);
    super.dispose();
  }

  bool _isPageActive(Offset origin) {
    if (_horizontalPosition == null) {
      return true;
    }
    final width = MediaQuery.sizeOf(context).width;
    return origin.dx >= -48 && origin.dx < width * 0.55;
  }

  void _resetForPageEnter() {
    _revealGen += 1;
    _measured = false;
    _armed = false;
    _animate = false;
    _measureRetries = 0;
    _visible = true;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkVisibility();
      }
    });
  }

  void _checkVisibility() {
    if (!mounted) {
      return;
    }

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.hasSize ||
        !renderObject.attached) {
      if (!_measured && _measureRetries < 8) {
        _measureRetries += 1;
        WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
      }
      return;
    }

    final origin = renderObject.localToGlobal(Offset.zero);
    final pageActive = _isPageActive(origin);
    if (!pageActive) {
      _pageActive = false;
      return;
    }

    if (!_pageActive) {
      _pageActive = true;
      // Anima apenas na primeira entrada; ao voltar para a aba o conteudo
      // ja revelado permanece visivel sem re-animar.
      if (!_enteredOnce) {
        _enteredOnce = true;
        _resetForPageEnter();
        return;
      }
    }

    final height = MediaQuery.sizeOf(context).height;
    final top = origin.dy;
    final inView = top < height * 0.88;
    final belowFold = top > height * 0.98;

    if (!_measured) {
      _measured = true;
      if (!belowFold) {
        _armed = true;
        if (!_visible) {
          setState(() {
            _visible = true;
            _animate = false;
          });
        }
        return;
      }

      setState(() {
        _visible = false;
        _animate = false;
      });
      return;
    }

    if (belowFold) {
      if (_armed || _visible) {
        _revealGen += 1;
        _armed = false;
        setState(() {
          _visible = false;
          _animate = false;
        });
      }
      return;
    }

    if (inView && !_visible && !_armed) {
      _reveal();
    }
  }

  Future<void> _reveal() async {
    _armed = true;
    final gen = _revealGen + 1;
    _revealGen = gen;
    if (widget.delay > Duration.zero) {
      await Future<void>.delayed(widget.delay);
      if (!mounted || gen != _revealGen) {
        return;
      }
    }

    setState(() {
      _animate = true;
      _visible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final duration = _animate ? widget.duration : Duration.zero;

    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: duration,
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.08),
        duration: duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
