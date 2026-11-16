import 'social_activity_item.dart';
import '../helpers/social_group_helpers.dart';
import 'social_group_summary.dart';
import 'social_ranking_entry.dart';

class SocialGroupDetail {
  const SocialGroupDetail({
    required this.group,
    required this.ranking,
    required this.recentActivities,
    this.hasMoreActivities = false,
  });

  final SocialGroupSummary group;
  final List<SocialRankingEntry> ranking;
  final List<SocialActivityItem> recentActivities;
  final bool hasMoreActivities;

  factory SocialGroupDetail.fromJson(Map<String, dynamic> json) {
    final recentActivities = (json['recentActivities'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SocialActivityItem.fromJson)
        .toList(growable: false);
    return SocialGroupDetail(
      group: SocialGroupSummary.fromJson(json['group'] as Map<String, dynamic>? ?? const {}),
      ranking: (json['ranking'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SocialRankingEntry.fromJson)
          .toList(growable: false),
      recentActivities: recentActivities,
      hasMoreActivities: json['hasMoreActivities'] == true ||
          recentActivities.length > socialGroupActivityPreviewLimit,
    );
  }
}
