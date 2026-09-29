import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../helpers/weight_history_chart_helpers.dart';
import '../models/weight_history.dart';

class WeightHistoryChart extends StatelessWidget {
  const WeightHistoryChart({super.key, required this.points, this.startDate});

  final List<WeightHistoryPoint> points;
  final DateTime? startDate;

  @override
  Widget build(BuildContext context) {
    final plotPoints = selectWeightChartPoints(points);
    if (plotPoints.isEmpty) {
      return Container(
        height: 88,
        alignment: Alignment.center,
        child: Text(
          'Sem registros de peso no período.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final sorted = [...plotPoints]..sort((a, b) => a.date.compareTo(b.date));
    final adjusted = latestWeightPerDay(sorted);
    final lastRecordDay = normalizeWeightChartDay(adjusted.last.date);
    final firstRecordDay = normalizeWeightChartDay(adjusted.first.date);
    final axisStart = resolveWeightChartAxisStart(
      firstRecordDay: firstRecordDay,
      lastRecordDay: lastRecordDay,
      periodStart: startDate,
    );
    final axisEnd = lastRecordDay;
    final measurementDays = countMeasurementDays(adjusted);
    final change = weightChangeKg(adjusted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _WeightChartStats(measurementDays: measurementDays, changeKg: change),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            const chartHeight = 220.0;
            final size = Size(width.isFinite ? width : 0, chartHeight);
            return SizedBox(
              height: chartHeight,
              width: double.infinity,
              child: CustomPaint(
                key: const ValueKey('weight-history-chart-paint'),
                size: size,
                painter: _WeightHistoryPainter(
                  points: adjusted,
                  startDate: axisStart,
                  endDate: axisEnd,
                ),
                child: const SizedBox.expand(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _WeightChartStats extends StatelessWidget {
  const _WeightChartStats({
    required this.measurementDays,
    required this.changeKg,
  });

  final int measurementDays;
  final double? changeKg;

  @override
  Widget build(BuildContext context) {
    final changeText = changeKg == null
        ? '—'
        : changeKg!.abs().toStringAsFixed(2).replaceAll('.', ',');

    return Row(
      children: <Widget>[
        Expanded(
          child: _StatBlock(
            label: 'Dias de medição',
            value: '$measurementDays',
          ),
        ),
        Container(width: 1, height: 36, color: AppColors.borderAlt),
        Expanded(
          child: _StatBlock(
            label: 'Mudança (kg)',
            value: changeText,
            alignEnd: true,
          ),
        ),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final cross = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Padding(
      padding: EdgeInsets.only(
        left: alignEnd ? AppSpacing.md : 0,
        right: alignEnd ? 0 : AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: cross,
        children: <Widget>[
          Text(
            label,
            style: AppTextStyles.performanceCardMicro.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.performanceSectionTitle.copyWith(
              color: AppColors.brand900Variant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightHistoryPainter extends CustomPainter {
  _WeightHistoryPainter({
    required this.points,
    required this.startDate,
    required this.endDate,
  });

  final List<WeightHistoryPoint> points;
  final DateTime startDate;
  final DateTime endDate;

  static const _axisLabelStyle = TextStyle(
    fontSize: 10,
    height: 1.2,
    color: AppColors.textSecondary,
    fontWeight: FontWeight.w400,
  );

  static const _valueLabelStyle = TextStyle(
    fontSize: 11,
    height: 1.2,
    color: AppColors.brand900Variant,
    fontWeight: FontWeight.w600,
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }

    const leftPadding = 8.0;
    const rightPadding = 40.0;
    const topPadding = 22.0;
    const bottomPadding = 28.0;
    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;
    if (chartWidth <= 0 || chartHeight <= 0) {
      return;
    }

    final scale = computeWeightChartScale(points.map((point) => point.weight));
    final startMs = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    ).millisecondsSinceEpoch.toDouble();
    final endMs = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    ).millisecondsSinceEpoch.toDouble();
    final timeRange = math.max(endMs - startMs, 1.0);

    final plotLeft = leftPadding;
    final plotRight = leftPadding + chartWidth;
    final plotTop = topPadding;
    final plotBottom = topPadding + chartHeight;

    final gridPaint = Paint()
      ..color = AppColors.borderAlt.withValues(alpha: 0.85)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = AppColors.brand900Variant.withValues(alpha: 0.85)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final pointFillPaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final pointBorderPaint = Paint()
      ..color = AppColors.brand900Variant
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    double xForDate(DateTime date) {
      final day = DateTime(date.year, date.month, date.day);
      final ms = day.millisecondsSinceEpoch.toDouble();
      final t = ((ms - startMs) / timeRange).clamp(0.0, 1.0);
      return plotLeft + (t * chartWidth);
    }

    double yForWeight(double weight) {
      return plotTop + ((scale.maxWeight - weight) / scale.range) * chartHeight;
    }

    for (final tick in scale.ticks) {
      final y = yForWeight(tick);
      _drawDashedLine(
        canvas,
        Offset(plotLeft, y),
        Offset(plotRight, y),
        gridPaint,
      );

      final label = TextPainter(
        text: TextSpan(text: tick.toStringAsFixed(1), style: _axisLabelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(plotRight + 6, y - (label.height / 2)));
    }

    final dateAxis = buildWeightChartDateAxis(
      startDate: startDate,
      endDate: endDate,
      maxLabels: _maxDateLabels(chartWidth),
    );
    _paintDateLabels(
      canvas,
      dates: dateAxis,
      xForDate: xForDate,
      plotLeft: plotLeft,
      plotRight: plotRight,
      plotTop: plotTop,
      plotBottom: plotBottom,
      gridPaint: gridPaint,
    );

    final offsets = points
        .map((point) => Offset(xForDate(point.date), yForWeight(point.weight)))
        .toList(growable: false);

    final linePath = _buildSmoothPath(offsets);
    final areaPath = Path.from(linePath);
    if (offsets.length == 1) {
      areaPath
        ..reset()
        ..moveTo(offsets.first.dx, plotBottom)
        ..lineTo(offsets.first.dx, offsets.first.dy)
        ..close();
      linePath.reset();
    } else if (offsets.isNotEmpty) {
      areaPath
        ..lineTo(offsets.last.dx, plotBottom)
        ..lineTo(offsets.first.dx, plotBottom)
        ..close();
    }

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          AppColors.brand900Variant.withValues(alpha: 0.16),
          AppColors.brand900Variant.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTRB(plotLeft, plotTop, plotRight, plotBottom))
      ..style = PaintingStyle.fill;

    canvas.drawPath(areaPath, areaPaint);
    canvas.drawPath(linePath, linePaint);

    final labeledIndexes = _valueLabelIndexes(points);
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final offset = offsets[i];
      canvas.drawCircle(offset, 4.2, pointFillPaint);
      canvas.drawCircle(offset, 4.2, pointBorderPaint);

      if (!labeledIndexes.contains(i)) {
        continue;
      }

      final valueLabel = TextPainter(
        text: TextSpan(
          text: _formatWeight(point.weight),
          style: _valueLabelStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final preferAbove = offset.dy > (plotTop + chartHeight * 0.28);
      var labelY = preferAbove
          ? offset.dy - valueLabel.height - 8
          : offset.dy + 8;
      labelY = labelY.clamp(plotTop - 4, plotBottom - valueLabel.height);
      final labelX = (offset.dx - (valueLabel.width / 2)).clamp(
        plotLeft,
        plotRight - valueLabel.width,
      );
      valueLabel.paint(canvas, Offset(labelX, labelY));
    }
  }

  int _maxDateLabels(double chartWidth) {
    const labelSlot = 44.0;
    return (chartWidth / labelSlot).floor().clamp(2, 5);
  }

  void _paintDateLabels(
    Canvas canvas, {
    required List<DateTime> dates,
    required double Function(DateTime date) xForDate,
    required double plotLeft,
    required double plotRight,
    required double plotTop,
    required double plotBottom,
    required Paint gridPaint,
  }) {
    if (dates.isEmpty) {
      return;
    }

    const minGap = 6.0;
    final labels = <({double x, TextPainter painter})>[];
    for (final date in dates) {
      final x = xForDate(DateTime(date.year, date.month, date.day, 12));
      _drawDashedLine(
        canvas,
        Offset(x, plotTop),
        Offset(x, plotBottom),
        gridPaint,
      );

      final painter = TextPainter(
        text: TextSpan(text: _dateLabel(date), style: _axisLabelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      labels.add((x: x, painter: painter));
    }

    final kept = <({double left, TextPainter painter})>[];
    for (var i = 0; i < labels.length; i++) {
      final item = labels[i];
      final isFirst = i == 0;
      final isLast = i == labels.length - 1;
      var left = item.x - (item.painter.width / 2);
      if (isFirst) {
        left = plotLeft;
      } else if (isLast) {
        left = plotRight - item.painter.width;
      }

      if (kept.isNotEmpty &&
          left < kept.last.left + kept.last.painter.width + minGap) {
        if (isLast) {
          kept.removeLast();
        } else {
          continue;
        }
      }

      kept.add((left: left, painter: item.painter));
    }

    for (final item in kept) {
      item.painter.paint(canvas, Offset(item.left, plotBottom + 8));
    }
  }

  Set<int> _valueLabelIndexes(List<WeightHistoryPoint> points) {
    if (points.length <= 7) {
      return Set<int>.from(List<int>.generate(points.length, (i) => i));
    }

    var minIndex = 0;
    var maxIndex = 0;
    for (var i = 1; i < points.length; i++) {
      if (points[i].weight < points[minIndex].weight) {
        minIndex = i;
      }
      if (points[i].weight > points[maxIndex].weight) {
        maxIndex = i;
      }
    }

    return <int>{0, minIndex, maxIndex, points.length - 1};
  }

  Path _buildSmoothPath(List<Offset> offsets) {
    final path = Path();
    if (offsets.isEmpty) {
      return path;
    }

    if (offsets.length == 1) {
      path.moveTo(offsets.first.dx, offsets.first.dy);
      return path;
    }

    if (offsets.length == 2) {
      path.moveTo(offsets.first.dx, offsets.first.dy);
      path.lineTo(offsets.last.dx, offsets.last.dy);
      return path;
    }

    path.moveTo(offsets.first.dx, offsets.first.dy);
    for (var i = 0; i < offsets.length - 1; i++) {
      final p0 = offsets[i == 0 ? i : i - 1];
      final p1 = offsets[i];
      final p2 = offsets[i + 1];
      final p3 = offsets[i + 2 < offsets.length ? i + 2 : i + 1];

      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }

    return path;
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dash = 3.5,
    double gap = 3.5,
  }) {
    final delta = end - start;
    final distance = delta.distance;
    if (distance <= 0) {
      return;
    }

    final direction = delta / distance;
    var traveled = 0.0;
    while (traveled < distance) {
      final dashEnd = math.min(traveled + dash, distance);
      canvas.drawLine(
        start + direction * traveled,
        start + direction * dashEnd,
        paint,
      );
      traveled += dash + gap;
    }
  }

  String _dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  String _formatWeight(double weight) {
    if ((weight * 100).roundToDouble() == weight.roundToDouble() * 100 &&
        weight == weight.roundToDouble()) {
      return weight.toStringAsFixed(0);
    }

    final asTwo = weight.toStringAsFixed(2);
    if (asTwo.endsWith('0')) {
      return weight.toStringAsFixed(1);
    }
    return asTwo;
  }

  @override
  bool shouldRepaint(covariant _WeightHistoryPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.startDate != startDate ||
        oldDelegate.endDate != endDate;
  }
}
