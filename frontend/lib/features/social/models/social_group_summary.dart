import 'social_activity_item.dart';
import '../helpers/social_model_parsers.dart';
import '../helpers/social_group_helpers.dart';

class SocialGroupSummary {
  const SocialGroupSummary({
    required this.id,
    required this.name,
    required this.description,
    required this.iconKey,
    required this.competitionType,
    required this.competitionLabel,
    required this.durationDays,
    required this.durationDaysLabel,
    required this.memberCount,
    required this.rankPosition,
    required this.points,
    required this.streakDays,
    required this.leaderName,
    required this.leaderLabel,
    required this.remainingDays,
    required this.remainingDaysLabel,
    this.isDefeated = false,
    this.isPublic = false,
    required this.inviteCode,
    required this.activities,
  });

  final String id;
  final String name;
  final String description;
  final String iconKey;
  final String competitionType;
  final String competitionLabel;
  final int durationDays;
  final String durationDaysLabel;
  final int memberCount;
  final int rankPosition;
  final num points;
  final int streakDays;
  final String leaderName;
  final String leaderLabel;
  final int remainingDays;
  final String remainingDaysLabel;
  final bool isDefeated;
  final bool isPublic;
  final String? inviteCode;
  final List<SocialActivityItem> activities;

  factory SocialGroupSummary.fromJson(Map<String, dynamic> json) {
    final durationDays = socialToInt(json['durationDays']) > 0 ? socialToInt(json['durationDays']) : 7;
    final remainingDays = socialToInt(json['remainingDays']);
    final competitionType = json['competitionType']?.toString() ?? 'offensive';
    final isDefeated = json['isDefeated'] == true;

    return SocialGroupSummary(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      iconKey: json['iconKey']?.toString() ?? 'salad',
      competitionType: competitionType,
      competitionLabel: socialCompetitionLabel(competitionType),
      durationDays: durationDays,
      durationDaysLabel: socialDurationLabel(durationDays),
      memberCount: socialToInt(json['memberCount']),
      rankPosition: socialToInt(json['rankPosition']),
      points: socialToNum(json['points']),
      streakDays: socialToInt(json['streakDays']),
      leaderName: json['leaderName']?.toString() ?? 'Líder do grupo',
      leaderLabel: json['leaderLabel']?.toString() ?? 'Líder do grupo',
      remainingDays: remainingDays,
      remainingDaysLabel: socialRemainingDaysLabelByGroup(
        remainingDays: remainingDays,
        competitionType: competitionType,
        isDefeated: isDefeated,
      ),
      isDefeated: isDefeated,
      isPublic: json['isPublic'] == true,
      inviteCode: json['inviteCode']?.toString(),
      activities: (json['activities'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SocialActivityItem.fromJson)
          .toList(growable: false),
    );
  }
}
