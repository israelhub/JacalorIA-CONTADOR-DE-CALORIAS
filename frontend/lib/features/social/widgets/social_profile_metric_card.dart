import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class SocialProfileMetricCard extends StatelessWidget {
  const SocialProfileMetricCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.performanceCardBorder, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 26),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _OverflowTapTooltipText(
                  text: label,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _OverflowTapTooltipText(
            text: value,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.brand900Variant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Truncates with ellipsis only when layout space is insufficient.
/// On tap (when overflowing), shows the full text in a floating tooltip.
class _OverflowTapTooltipText extends StatefulWidget {
  const _OverflowTapTooltipText({
    required this.text,
    required this.style,
  });

  final String text;
  final TextStyle style;

  static const int _maxLines = 2;

  @override
  State<_OverflowTapTooltipText> createState() =>
      _OverflowTapTooltipTextState();
}

class _OverflowTapTooltipTextState extends State<_OverflowTapTooltipText> {
  bool _isOverflowing = false;

  @override
  void didUpdateWidget(covariant _OverflowTapTooltipText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      _isOverflowing = false;
    }
  }

  void _updateOverflow(double maxWidth) {
    if (maxWidth <= 0) return;

    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: _OverflowTapTooltipText._maxLines,
      textDirection: TextDirection.ltr,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);

    final overflowing = painter.didExceedMaxLines;
    painter.dispose();

    if (overflowing == _isOverflowing) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || overflowing == _isOverflowing) return;
      setState(() => _isOverflowing = overflowing);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _updateOverflow(constraints.maxWidth);

        final textWidget = Text(
          widget.text,
          style: widget.style,
          maxLines: _OverflowTapTooltipText._maxLines,
          overflow: TextOverflow.ellipsis,
        );

        if (!_isOverflowing) {
          return textWidget;
        }

        return Tooltip(
          message: widget.text,
          triggerMode: TooltipTriggerMode.tap,
          preferBelow: true,
          waitDuration: Duration.zero,
          showDuration: const Duration(seconds: 5),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.brand900Variant,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          textStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.surface,
          ),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: textWidget,
          ),
        );
      },
    );
  }
}
