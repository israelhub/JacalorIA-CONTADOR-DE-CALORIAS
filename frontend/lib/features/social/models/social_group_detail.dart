import 'social_activity_item.dart';
import 'social_group_summary.dart';
import 'social_ranking_entry.dart';

class SocialGroupDetail {
  const SocialGroupDetail({
    required this.group,
    required this.ranking,
    required this.recentActivities,
  });

  final SocialGroupSummary group;
  final List<SocialRankingEntry> ranking;
  final List<SocialActivityItem> recentActivities;

  factory SocialGroupDetail.fromJson(Map<String, dynamic> json) {
    return SocialGroupDetail(
      group: SocialGroupSummary.fromJson(json['group'] as Map<String, dynamic>? ?? const {}),
      ranking: (json['ranking'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SocialRankingEntry.fromJson)
          .toList(growable: false),
      recentActivities: (json['recentActivities'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SocialActivityItem.fromJson)
          .toList(growable: false),
    );
  }
}
