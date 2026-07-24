import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

/// Medalha de conquista: quantidade em destaque sobre um selo com raios.
class ProfileAchievementMedal extends StatelessWidget {
  const ProfileAchievementMedal({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  static const double _medalSize = 64;
  static const double _pillOverlap = 12;

  final IconData icon;
  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final isUnlocked = value > 0;
    final medalColor = isUnlocked ? color : AppColors.textTertiary;

    return Semantics(
      label: '$label: $value',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _medalSize + _pillOverlap,
            width: _medalSize,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                _MedalSeal(icon: icon, color: medalColor, size: _medalSize),
                Positioned(
                  bottom: 0,
                  child: _MedalCountPill(color: medalColor, value: value),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.captionStrong.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MedalSeal extends StatelessWidget {
  const _MedalSeal({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _MedalRaysPainter(color: color.withValues(alpha: 0.38)),
          ),
          Container(
            width: size - 10,
            height: size - 10,
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_shift(color, 0.12), _shift(color, -0.10)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _shift(color, -0.22),
                    offset: const Offset(0, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Icon(icon, color: AppColors.surface, size: size * 0.42),
            ),
          ),
        ],
      ),
    );
  }

  static Color _shift(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }
}

class _MedalCountPill extends StatelessWidget {
  const _MedalCountPill({required this.color, required this.value});

  final Color color;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 1,
      ),
      constraints: const BoxConstraints(minWidth: 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color, width: 2),
        boxShadow: AppShadows.sm,
      ),
      child: Text(
        '$value',
        textAlign: TextAlign.center,
        maxLines: 1,
        style: AppTextStyles.missionsPillValue.copyWith(
          color: AppColors.brand900Variant,
        ),
      ),
    );
  }
}

class _MedalRaysPainter extends CustomPainter {
  const _MedalRaysPainter({required this.color});

  static const int _rayCount = 10;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.78;
    final angleStep = math.pi / _rayCount;
    final path = Path();

    for (var index = 0; index < _rayCount * 2; index++) {
      final radius = index.isEven ? outerRadius : innerRadius;
      final angle = -math.pi / 2 + index * angleStep;
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MedalRaysPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// Vitrine de conquistas do perfil (missões, sequência e visuais).
class ProfileAchievementsCard extends StatelessWidget {
  const ProfileAchievementsCard({
    super.key,
    required this.missionsCompleted,
    required this.longestStreakDays,
    required this.cosmeticsOwned,
  });

  final int missionsCompleted;
  final int longestStreakDays;
  final int cosmeticsOwned;

  @override
  Widget build(BuildContext context) {
    final medals = <Widget>[
      ProfileAchievementMedal(
        icon: Icons.emoji_events_rounded,
        color: AppColors.accent500,
        label: 'Missões completadas',
        value: missionsCompleted,
      ),
      ProfileAchievementMedal(
        icon: Icons.local_fire_department_rounded,
        color: AppColors.socialMetricStreak,
        label: 'Sequência mais alta',
        value: longestStreakDays,
      ),
      ProfileAchievementMedal(
        icon: Icons.palette_rounded,
        color: AppColors.missionsChallenge,
        label: 'Visuais adquiridos',
        value: cosmeticsOwned,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.performanceCardBorder, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: medals
            .map((medal) => Expanded(child: medal))
            .toList(growable: false),
      ),
    );
  }
}
