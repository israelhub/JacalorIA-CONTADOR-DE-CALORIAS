import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/avatar_frames/models/avatar_background_catalog.dart';
import '../../features/social/models/jaca_emoji_catalog.dart';
import '../theme/app_theme.dart';
import 'framed_avatar.dart';

class AvatarProfilePreview extends StatelessWidget {
  const AvatarProfilePreview({
    super.key,
    required this.avatarUrl,
    required this.frameId,
    required this.name,
    this.backgroundId,
    this.reactionEmojiId,
    this.showReactionBubble = false,
    this.onReactionTap,
    this.height = defaultHeight,
    this.avatarSize,
    this.borderRadius,
    this.composeHeight,
  });

  static const double _avatarScale = 4.15 / 3.4;

  static const double defaultHeight = 173 * _avatarScale;

  static const double edgeToEdgeContentHeight = 148 * _avatarScale;

  static const double edgeToEdgeBottomTrim = 36 * _avatarScale;

  static const double bannerAspectRatio = 598 / (177 * _avatarScale);

  static const double defaultAvatarSize = AppSpacing.huge * 4.15;

  static double edgeToEdgeComposeHeight({required double topOverlayHeight}) {
    return topOverlayHeight * 2 + edgeToEdgeContentHeight;
  }

  static double edgeToEdgeHeight({required double topOverlayHeight}) {
    return edgeToEdgeComposeHeight(topOverlayHeight: topOverlayHeight) -
        edgeToEdgeBottomTrim;
  }

  final String? avatarUrl;
  final String? frameId;
  final String? backgroundId;
  final String? reactionEmojiId;
  final bool showReactionBubble;
  final VoidCallback? onReactionTap;
  final String name;
  final double height;
  final double? avatarSize;
  final BorderRadius? borderRadius;
  final double? composeHeight;

  @override
  Widget build(BuildContext context) {
    final backgroundAssetPath = AvatarBackgroundCatalog.assetPathForId(
      backgroundId,
    );
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.lg);
    final resolvedAvatarSize = avatarSize ?? defaultAvatarSize;
    final paintedHeight = composeHeight ?? height;
    final reactionItem = JacaEmojiCatalog.byId(reactionEmojiId);
    final shouldShowBubble =
        showReactionBubble ||
        onReactionTap != null ||
        reactionItem != null;

    final painted = Container(
      width: double.infinity,
      height: paintedHeight,
      decoration: BoxDecoration(
        color: AppColors.homeProgressTrack,
        image: backgroundAssetPath == null
            ? null
            : DecorationImage(
                image: AssetImage(backgroundAssetPath),
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
      ),
      child: Center(
        child: SizedBox(
          width: resolvedAvatarSize * 1.28,
          height: resolvedAvatarSize * 1.18,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              FramedAvatar(
                size: resolvedAvatarSize,
                avatarUrl: avatarUrl,
                frameId: frameId,
                fallbackText: name,
                backgroundColor: AppColors.surface,
              ),
              if (shouldShowBubble)
                Positioned(
                  top: resolvedAvatarSize * 0.03,
                  right: -resolvedAvatarSize * 0.02,
                  child: _ProfileReactionBubble(
                    emoji: reactionItem,
                    onTap: onReactionTap,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (composeHeight == null || composeHeight! <= height) {
      return Container(
        width: double.infinity,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: radius),
        child: painted,
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minHeight: paintedHeight,
            maxHeight: paintedHeight,
            child: painted,
          ),
        ),
      ),
    );
  }
}

class _ProfileReactionBubble extends StatefulWidget {
  const _ProfileReactionBubble({required this.emoji, this.onTap});

  final JacaEmojiItem? emoji;
  final VoidCallback? onTap;

  @override
  State<_ProfileReactionBubble> createState() => _ProfileReactionBubbleState();
}

class _ProfileReactionBubbleState extends State<_ProfileReactionBubble>
    with SingleTickerProviderStateMixin {
  static const double _cloudWidth = 80;
  static const double _cloudHeight = 62;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emoji = widget.emoji;
    final content = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * math.pi * 2;
        final dx = math.cos(t) * 2.6 + math.cos(2 * t) * 0.4;
        final dy = 3.2 + math.sin(t) * 2.0 + math.sin(2 * t) * 0.3;
        return Transform.translate(
          offset: Offset(dx, dy),
          child: child,
        );
      },
      child: SizedBox(
        width: _cloudWidth + 4,
        height: _cloudHeight + 18,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 8,
              bottom: 0,
              child: _ThoughtDot(
                size: 5,
                color: AppColors.surface,
                borderColor: AppColors.performanceCardBorder,
              ),
            ),
            Positioned(
              left: 16,
              bottom: 7,
              child: _ThoughtDot(
                size: 8,
                color: AppColors.surface,
                borderColor: AppColors.performanceCardBorder,
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              child: SizedBox(
                width: _cloudWidth,
                height: _cloudHeight,
                child: CustomPaint(
                  painter: const _ThoughtCloudPainter(
                    fillColor: AppColors.surface,
                    borderColor: AppColors.performanceCardBorder,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(13, 10, 13, 12),
                      child: emoji == null
                          ? Icon(
                              Icons.emoji_emotions_outlined,
                              size: 36,
                              color: AppColors.textSecondary,
                            )
                          : Image.asset(
                              emoji.assetPath,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.emoji_emotions_outlined,
                                size: 36,
                                color: AppColors.textSecondary,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.onTap == null) {
      return content;
    }

    return Semantics(
      button: true,
      label: emoji == null
          ? 'Escolher reação do perfil'
          : 'Reação do perfil: ${emoji.label}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: content,
        ),
      ),
    );
  }
}

class _ThoughtDot extends StatelessWidget {
  const _ThoughtDot({
    required this.size,
    required this.color,
    required this.borderColor,
  });

  final double size;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1),
        boxShadow: AppShadows.sm,
      ),
    );
  }
}

class _ThoughtCloudPainter extends CustomPainter {
  const _ThoughtCloudPainter({
    required this.fillColor,
    required this.borderColor,
  });

  final Color fillColor;
  final Color borderColor;

  Path _cloudPath(Size size) {
    final w = size.width;
    final h = size.height;
    final midX = w * 0.5;
    final midY = h * 0.5;

    Path oval(double cx, double cy, double rw, double rh) {
      return Path()
        ..addOval(
          Rect.fromCenter(center: Offset(cx, cy), width: rw, height: rh),
        );
    }

    Path mirrorVertical(Path topHalf) {
      final matrix = Matrix4.identity()
        ..translateByDouble(0, midY, 0, 1)
        ..scaleByDouble(1, -1, 1, 1)
        ..translateByDouble(0, -midY, 0, 1);
      return Path.combine(
        PathOperation.union,
        topHalf,
        topHalf.transform(matrix.storage),
      );
    }

    Path leftRight(double dx, double cy, double rw, double rh) {
      return Path.combine(
        PathOperation.union,
        oval(midX - dx, cy, rw, rh),
        oval(midX + dx, cy, rw, rh),
      );
    }

    final top = <Path>[
      oval(midX, h * 0.52, w * 0.68, h * 0.36),
      oval(midX, h * 0.28, w * 0.34, h * 0.36),
      leftRight(w * 0.16, h * 0.34, w * 0.30, h * 0.34),
      leftRight(w * 0.22, h * 0.48, w * 0.26, h * 0.30),
    ];

    var topPath = top.first;
    for (var i = 1; i < top.length; i++) {
      topPath = Path.combine(PathOperation.union, topPath, top[i]);
    }

    return mirrorVertical(topPath);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _cloudPath(size);

    canvas.drawShadow(path, const Color(0x33000000), 4, true);
    canvas.drawPath(path, Paint()..color = fillColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ThoughtCloudPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor;
  }
}
