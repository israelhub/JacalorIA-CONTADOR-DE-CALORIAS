import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppToast {
  AppToast._();

  static const Color _errorBackground = Color(0xFF6B1F1A);

  static OverlayEntry? _activeEntry;

  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(milliseconds: 1800),
    bool isError = false,
    IconData? icon,
  }) {
    _activeEntry?.remove();
    _activeEntry = null;

    final overlay = Overlay.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastOverlay(
        message: message,
        icon: icon ??
            (isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_rounded),
        backgroundColor:
            isError ? _errorBackground : AppColors.brand900Variant,
        duration: duration,
        onClose: () {
          entry.remove();
          if (_activeEntry == entry) _activeEntry = null;
        },
      ),
    );

    _activeEntry = entry;
    overlay.insert(entry);
  }

  static void success(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(milliseconds: 1800),
  }) {
    show(context, message: message, duration: duration);
  }

  static void error(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(milliseconds: 1800),
  }) {
    show(context, message: message, duration: duration, isError: true);
  }
}

class _ToastOverlay extends StatefulWidget {
  const _ToastOverlay({
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.duration,
    required this.onClose,
  });

  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Duration duration;
  final VoidCallback onClose;

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 240),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
    _timer = Timer(widget.duration, () async {
      await _controller.reverse();
      if (mounted) widget.onClose();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Positioned(
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      bottom: bottomInset + AppSpacing.lg,
      child: IgnorePointer(
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: Colors.white, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
