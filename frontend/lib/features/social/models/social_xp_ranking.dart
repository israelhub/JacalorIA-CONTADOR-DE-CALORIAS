import '../helpers/social_model_parsers.dart';
import 'social_ranking_entry.dart';

enum SocialXpRankingPeriod {
  all,
  month,
  week;

  static SocialXpRankingPeriod fromApi(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'month':
      case 'mes':
      case 'mês':
        return SocialXpRankingPeriod.month;
      case 'week':
      case 'semana':
        return SocialXpRankingPeriod.week;
      default:
        return SocialXpRankingPeriod.all;
    }
  }

  String get apiValue => switch (this) {
    SocialXpRankingPeriod.all => 'all',
    SocialXpRankingPeriod.month => 'month',
    SocialXpRankingPeriod.week => 'week',
  };

  String get label => switch (this) {
    SocialXpRankingPeriod.all => 'Geral',
    SocialXpRankingPeriod.month => 'Mês',
    SocialXpRankingPeriod.week => 'Semana',
  };
}

class SocialXpRanking {
  const SocialXpRanking({
    required this.period,
    required this.ranking,
    required this.viewerPosition,
    required this.viewerPoints,
  });

  final SocialXpRankingPeriod period;
  final List<SocialRankingEntry> ranking;
  final int viewerPosition;
  final int viewerPoints;

  factory SocialXpRanking.fromJson(Map<String, dynamic> json) {
    final viewer = json['viewer'];
    final viewerMap = viewer is Map<String, dynamic> ? viewer : const <String, dynamic>{};
    return SocialXpRanking(
      period: SocialXpRankingPeriod.fromApi(json['period']?.toString()),
      ranking: (json['ranking'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SocialRankingEntry.fromJson)
          .toList(growable: false),
      viewerPosition: socialToInt(viewerMap['position']),
      viewerPoints: socialToInt(viewerMap['points']),
    );
  }
}
