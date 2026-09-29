import 'package:flutter/material.dart';

class SocialGroupChatAppear extends StatelessWidget {
  const SocialGroupChatAppear({
    super.key,
    required this.animate,
    required this.isMine,
    required this.child,
  });

  final bool animate;
  final bool isMine;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!animate) return child;
    return _AnimatedAppear(isMine: isMine, child: child);
  }
}

class _AnimatedAppear extends StatefulWidget {
  const _AnimatedAppear({required this.isMine, required this.child});

  final bool isMine;
  final Widget child;

  @override
  State<_AnimatedAppear> createState() => _AnimatedAppearState();
}

class _AnimatedAppearState extends State<_AnimatedAppear>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 280);

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fade = curved;
    _scale = Tween<double>(begin: 0.94, end: 1).animate(curved);
    _slide = Tween<Offset>(
      begin: Offset(widget.isMine ? 0.16 : -0.16, 0.08),
      end: Offset.zero,
    ).animate(curved);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          alignment: widget.isMine
              ? Alignment.bottomRight
              : Alignment.bottomLeft,
          scale: _scale,
          child: widget.child,
        ),
      ),
    );
  }
}
