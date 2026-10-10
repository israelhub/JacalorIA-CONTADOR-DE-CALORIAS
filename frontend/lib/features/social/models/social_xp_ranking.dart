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
    this.page = 1,
    this.pageSize = 10,
    this.total = 0,
    this.totalPages = 0,
  });

  final SocialXpRankingPeriod period;
  final List<SocialRankingEntry> ranking;
  final int viewerPosition;
  final int viewerPoints;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  factory SocialXpRanking.fromJson(Map<String, dynamic> json) {
    final viewer = json['viewer'];
    final viewerMap = viewer is Map<String, dynamic>
        ? viewer
        : const <String, dynamic>{};
    final ranking = (json['ranking'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SocialRankingEntry.fromJson)
        .toList(growable: false);
    final rawPageSize = socialToInt(json['pageSize']);
    final pageSize = rawPageSize > 0 ? rawPageSize : 10;
    final rawTotal = socialToInt(json['total']);
    final total = rawTotal > 0 ? rawTotal : ranking.length;
    final parsedTotalPages = socialToInt(json['totalPages']);
    final totalPages = parsedTotalPages > 0
        ? parsedTotalPages
        : (total == 0 ? 0 : ((total + pageSize - 1) ~/ pageSize));
    final rawPage = socialToInt(json['page']);
    return SocialXpRanking(
      period: SocialXpRankingPeriod.fromApi(json['period']?.toString()),
      ranking: ranking,
      viewerPosition: socialToInt(viewerMap['position']),
      viewerPoints: socialToInt(viewerMap['points']),
      page: rawPage > 0 ? rawPage : 1,
      pageSize: pageSize,
      total: total,
      totalPages: totalPages,
    );
  }
}
