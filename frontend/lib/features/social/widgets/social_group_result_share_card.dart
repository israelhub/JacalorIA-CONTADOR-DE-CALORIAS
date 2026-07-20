import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_theme.dart';
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
    const podium = 300.0;
    const listHeader = 72.0;
    const row = 108.0;
    const footer = 160.0;
    final restCount = ranking.length > 3 ? ranking.length - 3 : 0;
    final height =
        header +
        (ranking.isNotEmpty ? podium : 0) +
        (restCount > 0 ? listHeader + (restCount * row) : 24) +
        footer;
    return Size(cardWidth, height.clamp(1350, 3600));
  }

  @override
  Widget build(BuildContext context) {
    final group = detail.group;
    final ranking = detail.ranking;
    final competition = socialCompetitionLabel(group.competitionType);
    final top = ranking.take(3).toList(growable: false);
    final listEntries =
        ranking.length > 3 ? ranking.sublist(3) : const <SocialRankingEntry>[];

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
                            'Parabéns aos vencedores — desafio concluído!',
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
                if (top.isNotEmpty) ...[
                  const SizedBox(height: 36),
                  _PodiumRow(
                    entries: top,
                    competitionType: group.competitionType,
                  ),
                ],
                if (listEntries.isNotEmpty) ...[
                  const SizedBox(height: 36),
                  Text(
                    'DEMAIS COLOCAÇÕES',
                    style: GoogleFonts.nunito(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.4,
                      color: AppColors.brand300,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...listEntries.map(
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

String _initialLetter(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  return String.fromCharCode(trimmed.runes.first).toUpperCase();
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

class _PodiumRow extends StatelessWidget {
  const _PodiumRow({
    required this.entries,
    required this.competitionType,
  });

  final List<SocialRankingEntry> entries;
  final String competitionType;

  @override
  Widget build(BuildContext context) {
    SocialRankingEntry? at(int index) =>
        index < entries.length ? entries[index] : null;

    final first = at(0);
    final second = at(1);
    final third = at(2);

    return SizedBox(
      height: 260,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: second == null
                ? const SizedBox.shrink()
                : _PodiumSlot(
                    entry: second,
                    competitionType: competitionType,
                    place: second.position,
                    height: 170,
                    accent: const Color(0xFF9EA7B3),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: first == null
                ? const SizedBox.shrink()
                : _PodiumSlot(
                    entry: first,
                    competitionType: competitionType,
                    place: first.position,
                    height: 220,
                    accent: const Color(0xFFE3B640),
                    isChampion: first.position == 1,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: third == null
                ? const SizedBox.shrink()
                : _PodiumSlot(
                    entry: third,
                    competitionType: competitionType,
                    place: third.position,
                    height: 150,
                    accent: const Color(0xFFB8793F),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({
    required this.entry,
    required this.competitionType,
    required this.place,
    required this.height,
    required this.accent,
    this.isChampion = false,
  });

  final SocialRankingEntry entry;
  final String competitionType;
  final int place;
  final double height;
  final Color accent;
  final bool isChampion;

  @override
  Widget build(BuildContext context) {
    final metric = socialRankingMetric(
      competitionType: competitionType,
      points: entry.points,
      streakDays: entry.streakDays,
    );
    final initial = _initialLetter(entry.name);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isChampion)
          Icon(Icons.emoji_events_rounded, color: accent, size: 42),
        Container(
          width: isChampion ? 96 : 80,
          height: isChampion ? 96 : 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(color: accent, width: 4),
          ),
          child: Text(
            initial,
            style: GoogleFonts.baloo2(
              fontSize: isChampion ? 42 : 34,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          entry.name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.nunito(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              metric.displayValue,
              style: GoogleFonts.baloo2(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
            const SizedBox(width: 4),
            Icon(metric.icon, size: 22, color: accent),
          ],
        ),
        Text(
          metric.label,
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: height * 0.28,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.28),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            border: Border.all(color: accent.withValues(alpha: 0.55), width: 2),
          ),
          child: Text(
            '$placeº',
            style: GoogleFonts.baloo2(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
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
    final initial = _initialLetter(entry.name);
    final highlight = entry.isCurrentUser;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.action500.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlight
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
                color: AppColors.brand300,
              ),
            ),
          ),
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.14),
            ),
            child: Text(
              initial,
              style: GoogleFonts.baloo2(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
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
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(metric.icon, size: 24, color: metric.iconColor),
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
