import 'package:flutter/material.dart';

import '../../features/avatar_frames/models/avatar_frame_catalog.dart';
import '../theme/app_theme.dart';

class FramedAvatar extends StatelessWidget {
  const FramedAvatar({
    super.key,
    required this.size,
    this.avatarUrl,
    this.frameId,
    this.fallbackText,
    this.onTap,
    this.backgroundColor = AppColors.surfaceAlt,
    this.framedAvatarScale = 0.74,
    this.unframedAvatarScale = 0.9,
  });

  final double size;
  final String? avatarUrl;
  final String? frameId;
  final String? fallbackText;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final double framedAvatarScale;
  final double unframedAvatarScale;

  @override
  Widget build(BuildContext context) {
    final frame = AvatarFrameCatalog.byId(frameId);
    final hasFrame = frame?.assetPath != null;
    final avatarSize = hasFrame
        ? size * _effectiveFramedAvatarScale(frameId)
        : size * unframedAvatarScale;
    final avatar = _AvatarCircle(
      size: avatarSize,
      avatarUrl: avatarUrl,
      fallbackText: fallbackText,
      backgroundColor: backgroundColor,
    );

    final content = SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          avatar,
          if (hasFrame)
            Positioned.fill(
              child: IgnorePointer(
                child: Image.asset(frame!.assetPath!, fit: BoxFit.contain),
              ),
            ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return _PressableAvatar(onTap: onTap!, child: content);
  }

  double _effectiveFramedAvatarScale(String? id) {
    switch (id?.trim()) {
      case 'cat_ears_soft':
        return 0.8;
      case 'gator_tail_fin':
        return 0.86;
      default:
        return framedAvatarScale;
    }
  }
}

class _PressableAvatar extends StatefulWidget {
  const _PressableAvatar({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_PressableAvatar> createState() => _PressableAvatarState();
}

class _PressableAvatarState extends State<_PressableAvatar> {
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
    _setPressed(true);
    widget.onTap();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (!mounted) {
      return;
    }
    _setPressed(false);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) {},
        onTap: _handleTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : (_isHovered ? 1.02 : 1),
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.size,
    required this.avatarUrl,
    required this.fallbackText,
    required this.backgroundColor,
  });

  final double size;
  final String? avatarUrl;
  final String? fallbackText;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveAvatarUrl(avatarUrl);
    final initial = fallbackText?.trim().isNotEmpty == true
        ? fallbackText!.trim()[0].toUpperCase()
        : null;

    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: imageUrl != null
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _FallbackAvatar(
                  initial: initial,
                  backgroundColor: backgroundColor,
                ),
              )
            : _FallbackAvatar(
                initial: initial,
                backgroundColor: backgroundColor,
              ),
      ),
    );
  }

  String? _resolveAvatarUrl(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) {
      return null;
    }

    return value;
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({required this.initial, required this.backgroundColor});

  final String? initial;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: Center(
        child: initial == null
            ? const Icon(Icons.person, color: AppColors.textSecondary)
            : Text(
                initial!,
                style: AppTextStyles.homeMealTitle.copyWith(
                  color: AppColors.brand900Variant,
                ),
              ),
      ),
    );
  }
}
