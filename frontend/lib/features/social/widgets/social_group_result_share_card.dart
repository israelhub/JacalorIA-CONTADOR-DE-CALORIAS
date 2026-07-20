import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/framed_avatar.dart';
import '../helpers/social_group_helpers.dart';
import '../models/social_group_models.dart';

/// Instagram-ready finished-group result card (logical 1080×auto).
class SocialGroupResultShareCard extends StatelessWidget {
  const SocialGroupResultShareCard({
    super.key,
    required this.detail,
  });

  static const double cardWidth = 1080;

  final SocialGroupDetail detail;

  static Size measureLogicalSize(SocialGroupDetail detail) {
    final ranking = detail.ranking;
    const header = 420.0;
    const listHeader = 72.0;
    const row = 118.0;
    const footer = 160.0;
    final height =
        header +
        (ranking.isNotEmpty ? listHeader + (ranking.length * row) : 24) +
        footer;
    return Size(cardWidth, height.clamp(1350, 3600));
  }

  @override
  Widget build(BuildContext context) {
    final group = detail.group;
    final ranking = detail.ranking;
    final competition = socialCompetitionLabel(group.competitionType);

    return Container(
      width: cardWidth,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF14281F),
            Color(0xFF1E513E),
            Color(0xFF193629),
          ],
          stops: [0, 0.55, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _GlowOrb(
              size: 420,
              color: AppColors.action500.withValues(alpha: 0.22),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -100,
            child: _GlowOrb(
              size: 360,
              color: AppColors.accent500.withValues(alpha: 0.14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 64, 56, 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RESULTADO FINAL',
                            style: GoogleFonts.nunito(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 3.2,
                              color: AppColors.brand300,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            group.name.trim().isEmpty ? 'Grupo' : group.name.trim(),
                            style: GoogleFonts.baloo2(
                              fontSize: 72,
                              height: 0.95,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 22),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _TagChip(
                                label: competition,
                                background: AppColors.action500,
                                foreground: Colors.white,
                              ),
                              if (group.durationDaysLabel.trim().isNotEmpty)
                                _TagChip(
                                  label: group.durationDaysLabel,
                                  background: Colors.white.withValues(alpha: 0.12),
                                  foreground: Colors.white,
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Parabéns aos vencedores! Desafio concluído!',
                            style: GoogleFonts.nunito(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Image.asset(
                      'assets/images/Jaca_acenando_v2.webp',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        width: 160,
                        height: 160,
                      ),
                    ),
                  ],
                ),
                if (ranking.isNotEmpty) ...[
                  const SizedBox(height: 36),
                  Text(
                    'RANKING FINAL',
                    style: GoogleFonts.nunito(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.4,
                      color: AppColors.brand300,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...ranking.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _RankRow(
                        entry: entry,
                        competitionType: group.competitionType,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 28),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Jacaloria',
                        style: GoogleFonts.baloo2(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'jacaloria.online',
                        style: GoogleFonts.nunito(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brand300,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}

Color? _placeAccent(int position) {
  switch (position) {
    case 1:
      return const Color(0xFFE3B640);
    case 2:
      return const Color(0xFF9EA7B3);
    case 3:
      return const Color(0xFFB8793F);
    default:
      return null;
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.entry,
    required this.competitionType,
  });

  final SocialRankingEntry entry;
  final String competitionType;

  @override
  Widget build(BuildContext context) {
    final metric = socialRankingMetric(
      competitionType: competitionType,
      points: entry.points,
      streakDays: entry.streakDays,
    );
    final highlight = entry.isCurrentUser;
    final accent = _placeAccent(entry.position);
    final placeColor = accent ?? AppColors.brand300;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.action500.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accent != null
              ? accent.withValues(alpha: 0.65)
              : highlight
                  ? AppColors.action500.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.1),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              '${entry.position}º',
              style: GoogleFonts.baloo2(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: placeColor,
              ),
            ),
          ),
          Container(
            decoration: accent == null
                ? null
                : BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: accent, width: 3),
                  ),
            padding: accent == null ? EdgeInsets.zero : const EdgeInsets.all(2),
            child: FramedAvatar(
              size: 64,
              avatarUrl: entry.avatarUrl,
              frameId: entry.avatarFrameId,
              fallbackText: entry.name,
              backgroundColor: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(
                    metric.displayValue,
                    style: GoogleFonts.baloo2(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: accent ?? Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    metric.icon,
                    size: 24,
                    color: accent ?? metric.iconColor,
                  ),
                ],
              ),
              Text(
                metric.label,
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
