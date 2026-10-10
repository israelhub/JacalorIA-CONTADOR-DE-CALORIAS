import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../helpers/home_date_helpers.dart';
import '../helpers/home_water_helpers.dart';

class HomeWaterCard extends StatelessWidget {
  const HomeWaterCard({
    super.key,
    required this.days,
    required this.selectedDate,
    required this.goalMl,
    required this.onAdd,
  });

  final List<HomeWaterDay> days;
  final DateTime selectedDate;
  final int goalMl;
  final VoidCallback onAdd;

  static const _mascotAsset = 'assets/images/jaca_water_drink.png';
  static const double cardHeight = 150;
  static const double _panelWidth = 120;

  @override
  Widget build(BuildContext context) {
    final selectedMl =
        days
            .where((day) => isSameHomeDate(day.date, selectedDate))
            .map((day) => day.milliliters)
            .firstOrNull ??
        0;
    final radius = BorderRadius.circular(AppRadius.lg);

    return Container(
      key: const ValueKey('home-water-card'),
      width: double.infinity,
      height: cardHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.homeWater,
        borderRadius: radius,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: _panelWidth,
            child: Image.asset(
              _mascotAsset,
              fit: BoxFit.cover,
              alignment: const Alignment(-0.35, -0.15),
            ),
          ),
          Positioned.fill(
            left: _panelWidth - AppSpacing.lg,
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registre sua água!',
                      style: AppTextStyles.homeSectionTitle.copyWith(
                        color: AppColors.surface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _WaterRing(milliliters: selectedMl, goalMl: goalMl),
                        const SizedBox(width: AppSpacing.md),
                        _CupAddButton(onPressed: onAdd),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaterRing extends StatelessWidget {
  const _WaterRing({required this.milliliters, required this.goalMl});

  final int milliliters;
  final int goalMl;

  @override
  Widget build(BuildContext context) {
    final progress = goalMl <= 0 ? 0.0 : (milliliters / goalMl).clamp(0.0, 1.0);
    final inLiters = milliliters >= 1000;
    final value = inLiters
        ? (milliliters % 1000 == 0
              ? (milliliters / 1000).toStringAsFixed(0)
              : (milliliters / 1000).toStringAsFixed(1).replaceAll('.', ','))
        : '$milliliters';

    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(80, 80),
            painter: _WaterRingPainter(fraction: progress),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                key: const ValueKey('home-water-ring-value'),
                style: AppTextStyles.statValue.copyWith(
                  color: AppColors.surface,
                ),
              ),
              Text(
                inLiters ? 'L' : 'ml',
                style: AppTextStyles.micro.copyWith(color: AppColors.surface),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CupAddButton extends StatelessWidget {
  const _CupAddButton({required this.onPressed});

  final VoidCallback onPressed;

  static const double width = 52;
  static const double height = 68;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Adicionar água',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('home-water-add'),
          onTap: onPressed,
          customBorder: const _CupBorder(),
          child: CustomPaint(
            size: const Size(width, height),
            painter: const _CupPainter(),
            child: const SizedBox(
              width: width,
              height: height,
              child: Align(
                alignment: Alignment(0, 0.12),
                child: Icon(
                  Icons.add_rounded,
                  color: AppColors.homeWater,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CupBorder extends ShapeBorder {
  const _CupBorder();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return _cupPath(rect);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return _cupPath(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => const _CupBorder();
}

class _CupPainter extends CustomPainter {
  const _CupPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = _cupPath(Offset.zero & size);
    canvas.drawPath(path, Paint()..color = AppColors.surface);
  }

  @override
  bool shouldRepaint(covariant _CupPainter oldDelegate) => false;
}

Path _cupPath(Rect rect) {
  final rim = rect.height * 0.14;
  final insetTop = rect.width * 0.04;
  final insetBottom = rect.width * 0.18;
  final radius = rect.width * 0.16;
  final path = Path()
    ..moveTo(rect.left + insetTop, rect.top + rim)
    ..lineTo(rect.left + insetBottom, rect.bottom - radius)
    ..quadraticBezierTo(
      rect.left + insetBottom,
      rect.bottom,
      rect.left + insetBottom + radius,
      rect.bottom,
    )
    ..lineTo(rect.right - insetBottom - radius, rect.bottom)
    ..quadraticBezierTo(
      rect.right - insetBottom,
      rect.bottom,
      rect.right - insetBottom,
      rect.bottom - radius,
    )
    ..lineTo(rect.right - insetTop, rect.top + rim)
    ..close()
    ..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left, rect.top, rect.width, rim + 3),
        const Radius.circular(5),
      ),
    );
  return path;
}

class _WaterRingPainter extends CustomPainter {
  _WaterRingPainter({required this.fraction});

  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = AppColors.surface.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final fillPaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    final sweep = math.pi * 2 * fraction.clamp(0.0, 1.0);
    if (sweep > 0) {
      canvas.drawArc(rect, -math.pi / 2, sweep, false, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaterRingPainter oldDelegate) {
    return oldDelegate.fraction != fraction;
  }
}
