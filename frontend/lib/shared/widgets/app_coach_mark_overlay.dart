import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_button.dart';

class AppCoachMarkHighlight {
  const AppCoachMarkHighlight({
    required this.rect,
    this.radius = AppRadius.lg,
  });

  final Rect rect;
  final double radius;
}

enum AppCoachMarkTooltipPlacement { above, below, auto }

class AppCoachMarkOverlay extends StatefulWidget {
  const AppCoachMarkOverlay({
    super.key,
    required this.title,
    required this.description,
    required this.stepIndex,
    required this.stepCount,
    required this.onNext,
    this.highlights = const <AppCoachMarkHighlight>[],
    this.nextLabel = 'Próximo',
    this.allowHighlightTap = false,
    this.showChrome = true,
    this.tooltipPlacement = AppCoachMarkTooltipPlacement.auto,
  });

  final String title;
  final String description;
  final int stepIndex;
  final int stepCount;
  final VoidCallback onNext;
  final List<AppCoachMarkHighlight> highlights;
  final String nextLabel;
  final bool allowHighlightTap;
  final bool showChrome;
  final AppCoachMarkTooltipPlacement tooltipPlacement;

  static const _tooltipMaxWidth = 320.0;
  static const _tooltipGap = AppSpacing.md;
  static const _edgePadding = AppSpacing.md;

  @override
  State<AppCoachMarkOverlay> createState() => _AppCoachMarkOverlayState();
}

class _AppCoachMarkOverlayState extends State<AppCoachMarkOverlay> {
  final GlobalKey _tooltipKey = GlobalKey(debugLabel: 'coach-mark-tooltip');
  double? _tooltipHeight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureTooltip());
  }

  @override
  void didUpdateWidget(covariant AppCoachMarkOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureTooltip());
  }

  void _measureTooltip() {
    if (!widget.showChrome) {
      if (_tooltipHeight != null && mounted) {
        setState(() => _tooltipHeight = null);
      }
      return;
    }
    final context = _tooltipKey.currentContext;
    if (context == null || !mounted) {
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) {
      return;
    }
    final next = box.size.height;
    if (_tooltipHeight == next) {
      return;
    }
    setState(() {
      _tooltipHeight = next;
    });
  }

  Rect? get _primaryHighlight {
    if (widget.highlights.isEmpty) {
      return null;
    }
    return widget.highlights.first.rect;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final highlights =
        widget.showChrome ? widget.highlights : const <AppCoachMarkHighlight>[];
    final primary = widget.showChrome ? _primaryHighlight : null;

    // Card do tutorial fica acima do scrim (opaco). Sem buraco no scrim nele,
    // senao a area clara fica maior que o proprio card.
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _CoachMarkScrimPainter(
              color: Colors.black.withValues(alpha: 0.55),
              highlights: highlights,
              absorbOutsideHoles:
                  !widget.allowHighlightTap || !widget.showChrome,
            ),
          ),
        ),
        if (widget.showChrome)
          for (final highlight in highlights)
            Positioned.fromRect(
              rect: highlight.rect,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(highlight.radius),
                    border: Border.all(
                      color: AppColors.action500,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
        if (widget.showChrome)
          Positioned(
            left: AppCoachMarkOverlay._edgePadding,
            right: AppCoachMarkOverlay._edgePadding,
            top: _tooltipTop(
              viewportHeight: size.height,
              safeTop: padding.top,
              safeBottom: padding.bottom,
              highlight: primary,
              measuredHeight: _tooltipHeight,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppCoachMarkOverlay._tooltipMaxWidth,
                ),
                child: KeyedSubtree(
                  key: _tooltipKey,
                  child: _CoachMarkTooltipCard(
                    title: widget.title,
                    description: widget.description,
                    stepIndex: widget.stepIndex,
                    stepCount: widget.stepCount,
                    nextLabel: widget.nextLabel,
                    onNext: widget.onNext,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  double _tooltipTop({
    required double viewportHeight,
    required double safeTop,
    required double safeBottom,
    required Rect? highlight,
    required double? measuredHeight,
  }) {
    final cardHeight = measuredHeight ?? 200.0;
    final minTop = safeTop + AppCoachMarkOverlay._edgePadding;
    final maxTop =
        viewportHeight -
        safeBottom -
        cardHeight -
        AppCoachMarkOverlay._edgePadding;

    if (highlight == null) {
      return (viewportHeight - cardHeight) / 2;
    }

    final spaceAbove = highlight.top - safeTop;
    final spaceBelow = viewportHeight - safeBottom - highlight.bottom;
    final need = cardHeight + AppCoachMarkOverlay._tooltipGap;

    var preferAbove = switch (widget.tooltipPlacement) {
      AppCoachMarkTooltipPlacement.above => true,
      AppCoachMarkTooltipPlacement.below => false,
      AppCoachMarkTooltipPlacement.auto =>
        spaceAbove >= need || spaceAbove >= spaceBelow,
    };

    // Se o lado pedido nao cabe, vira pro outro.
    if (preferAbove && spaceAbove < need && spaceBelow >= need) {
      preferAbove = false;
    } else if (!preferAbove && spaceBelow < need && spaceAbove >= need) {
      preferAbove = true;
    }

    final ideal = preferAbove
        ? highlight.top - cardHeight - AppCoachMarkOverlay._tooltipGap
        : highlight.bottom + AppCoachMarkOverlay._tooltipGap;
    return ideal.clamp(minTop, maxTop).toDouble();
  }
}

class _CoachMarkTooltipCard extends StatelessWidget {
  const _CoachMarkTooltipCard({
    required this.title,
    required this.description,
    required this.stepIndex,
    required this.stepCount,
    required this.nextLabel,
    required this.onNext,
  });

  final String title;
  final String description;
  final int stepIndex;
  final int stepCount;
  final String nextLabel;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderBrandAlt, width: 1.4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.subtitleLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${stepIndex + 1}/$stepCount',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: nextLabel, onPressed: onNext),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoachMarkScrimPainter extends CustomPainter {
  const _CoachMarkScrimPainter({
    required this.color,
    required this.highlights,
    required this.absorbOutsideHoles,
  });

  final Color color;
  final List<AppCoachMarkHighlight> highlights;
  final bool absorbOutsideHoles;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = color;
    if (highlights.isEmpty) {
      canvas.drawRect(Offset.zero & size, scrim);
      return;
    }

    final path = Path()..addRect(Offset.zero & size);
    for (final highlight in highlights) {
      path.addRRect(
        RRect.fromRectAndRadius(
          highlight.rect,
          Radius.circular(highlight.radius),
        ),
      );
    }
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, scrim);
  }

  @override
  bool? hitTest(Offset position) {
    for (final highlight in highlights) {
      if (highlight.rect.contains(position)) {
        return absorbOutsideHoles ? true : false;
      }
    }
    return true;
  }

  @override
  bool shouldRepaint(covariant _CoachMarkScrimPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.highlights != highlights ||
        oldDelegate.absorbOutsideHoles != absorbOutsideHoles;
  }
}
