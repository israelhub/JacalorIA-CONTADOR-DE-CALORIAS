import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../models/weight_history.dart';

class WeightHistoryChart extends StatelessWidget {
  const WeightHistoryChart({super.key, required this.points});

  final List<WeightHistoryPoint> points;

  @override
  Widget build(BuildContext context) {
    final sorted = [...points]..sort((a, b) => a.date.compareTo(b.date));
    final adjusted = _spreadSameDayPoints(sorted);
    final chartHeight = _chartHeight(adjusted.length);

    if (points.isEmpty) {
      return Container(
        height: 88,
        alignment: Alignment.center,
        child: Text(
          'Sem registros de peso no período.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: <Widget>[
        SizedBox(
          height: chartHeight,
          width: double.infinity,
          child: CustomPaint(
            painter: _WeightHistoryPainter(adjusted),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              _dateLabel(adjusted.first.date),
              style: AppTextStyles.performanceCardMicro.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              _dateLabel(adjusted.last.date),
              style: AppTextStyles.performanceCardMicro.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  double _chartHeight(int length) {
    if (length <= 2) {
      return 150;
    }

    if (length <= 7) {
      return 180;
    }

    return 190;
  }

  List<WeightHistoryPoint> _spreadSameDayPoints(List<WeightHistoryPoint> sorted) {
    final groupedByDay = <DateTime, List<WeightHistoryPoint>>{};
    for (final point in sorted) {
      final key = DateTime(point.date.year, point.date.month, point.date.day);
      groupedByDay.putIfAbsent(key, () => <WeightHistoryPoint>[]).add(point);
    }

    final adjusted = <WeightHistoryPoint>[];
    final orderedDays = groupedByDay.keys.toList()..sort();
    for (final day in orderedDays) {
      final dayPoints = groupedByDay[day]!..sort((a, b) => a.date.compareTo(b.date));
      if (dayPoints.length == 1) {
        adjusted.add(dayPoints.first);
        continue;
      }

      for (var i = 0; i < dayPoints.length; i++) {
        final source = dayPoints[i];
        final displacedDate = DateTime(
          day.year,
          day.month,
          day.day,
          math.min(i * 2, 23),
          0,
        );
        adjusted.add(
          WeightHistoryPoint(date: displacedDate, weight: source.weight),
        );
      }
    }

    adjusted.sort((a, b) => a.date.compareTo(b.date));
    return adjusted;
  }
}

class _WeightHistoryPainter extends CustomPainter {
  _WeightHistoryPainter(this.points);

  final List<WeightHistoryPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }

    const horizontalPadding = 36.0;
    const verticalPadding = 14.0;
    final chartWidth = size.width - (horizontalPadding * 2);
    final chartHeight = size.height - (verticalPadding * 2);
    if (chartWidth <= 0 || chartHeight <= 0) {
      return;
    }

    final minWeight = points.map((e) => e.weight).reduce(math.min);
    final maxWeight = points.map((e) => e.weight).reduce(math.max);
    final weightRange = (maxWeight - minWeight).abs() < 0.1 ? 0.1 : maxWeight - minWeight;
    final start = points.first.date.millisecondsSinceEpoch.toDouble();
    final end = points.last.date.millisecondsSinceEpoch.toDouble();
    final timeRange = (end - start).abs() < 1 ? 1 : end - start;

    final linePaint = Paint()
      ..color = AppColors.brand900Variant.withValues(alpha: 0.7)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = AppColors.brand900Variant
      ..style = PaintingStyle.fill;

    final highlightedPointPaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.fill;

    final highlightedPointBorderPaint = Paint()
      ..color = AppColors.brand900Variant
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final gridPaint = Paint()
      ..color = AppColors.borderAlt.withValues(alpha: 0.5)
      ..strokeWidth = 0.8;

    final areaPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color.fromRGBO(100, 120, 150, 0.14),
          Color.fromRGBO(100, 120, 150, 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final areaPath = Path();
    final yTop = verticalPadding;
    final yMiddle = verticalPadding + (chartHeight / 2);
    final yBottom = verticalPadding + chartHeight;

    canvas.drawLine(
      Offset(horizontalPadding, yTop),
      Offset(horizontalPadding + chartWidth, yTop),
      gridPaint,
    );
    canvas.drawLine(
      Offset(horizontalPadding, yMiddle),
      Offset(horizontalPadding + chartWidth, yMiddle),
      gridPaint,
    );
    canvas.drawLine(
      Offset(horizontalPadding, yBottom),
      Offset(horizontalPadding + chartWidth, yBottom),
      gridPaint,
    );

    final maxLabel = TextPainter(
      text: TextSpan(
        text: maxWeight.toStringAsFixed(1),
        style: AppTextStyles.performanceCardMicro.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    maxLabel.paint(canvas, Offset(size.width - horizontalPadding + 4, yTop - (maxLabel.height / 2)));

    final minLabel = TextPainter(
      text: TextSpan(
        text: minWeight.toStringAsFixed(1),
        style: AppTextStyles.performanceCardMicro.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    minLabel.paint(canvas, Offset(size.width - horizontalPadding + 4, yBottom - (minLabel.height / 2)));

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final x = horizontalPadding +
          (((point.date.millisecondsSinceEpoch - start) / timeRange) * chartWidth);
      final y = verticalPadding +
          ((maxWeight - point.weight) / weightRange) * chartHeight;

      if (i == 0) {
        path.moveTo(x, y);
        areaPath.moveTo(x, verticalPadding + chartHeight);
        areaPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        areaPath.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 2.3, pointPaint);
    }

    if (points.length == 1) {
      final singleY = verticalPadding + ((maxWeight - points.first.weight) / weightRange) * chartHeight;
      path.moveTo(horizontalPadding, singleY);
      path.lineTo(horizontalPadding + chartWidth, singleY);
      areaPath.moveTo(horizontalPadding, verticalPadding + chartHeight);
      areaPath.lineTo(horizontalPadding, singleY);
      areaPath.lineTo(horizontalPadding + chartWidth, singleY);
      areaPath.lineTo(horizontalPadding + chartWidth, verticalPadding + chartHeight);
      areaPath.close();
    }

    final lastX = horizontalPadding +
        (((points.last.date.millisecondsSinceEpoch - start) / timeRange) * chartWidth);
    final lastY = verticalPadding +
        ((maxWeight - points.last.weight) / weightRange) * chartHeight;

    if (points.length > 1) {
      areaPath.lineTo(lastX, verticalPadding + chartHeight);
      areaPath.close();
    }

    canvas.drawPath(areaPath, areaPaint);
    canvas.drawPath(path, linePaint);
    canvas.drawCircle(Offset(lastX, lastY), 4.0, highlightedPointPaint);
    canvas.drawCircle(Offset(lastX, lastY), 4.0, highlightedPointBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _WeightHistoryPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
