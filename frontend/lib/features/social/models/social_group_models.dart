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
  final int points;
  final int streakDays;
  final String leaderName;
  final String leaderLabel;
  final int remainingDays;
  final String remainingDaysLabel;
  final String? inviteCode;
  final List<SocialActivityItem> activities;

  factory SocialGroupSummary.fromJson(Map<String, dynamic> json) {
    return SocialGroupSummary(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      iconKey: json['iconKey']?.toString() ?? 'salad',
      competitionType: json['competitionType']?.toString() ?? 'offensive',
      competitionLabel: json['competitionLabel']?.toString() ?? 'Ofensiva',
      durationDays: _toInt(json['durationDays']) > 0
          ? _toInt(json['durationDays'])
          : 7,
      durationDaysLabel:
          json['durationDaysLabel']?.toString() ??
          '${_toInt(json['durationDays']) > 0 ? _toInt(json['durationDays']) : 7} dias',
      memberCount: _toInt(json['memberCount']),
      rankPosition: _toInt(json['rankPosition']),
      points: _toInt(json['points']),
      streakDays: _toInt(json['streakDays']),
      leaderName: json['leaderName']?.toString() ?? 'Líder do grupo',
      leaderLabel: json['leaderLabel']?.toString() ?? 'Líder do grupo',
      remainingDays: _toInt(json['remainingDays']),
      remainingDaysLabel:
          json['remainingDaysLabel']?.toString() ??
          '${_toInt(json['remainingDays'])} dias restantes',
      inviteCode: json['inviteCode']?.toString(),
      activities: (json['activities'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SocialActivityItem.fromJson)
          .toList(growable: false),
    );
  }
}

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
      group: SocialGroupSummary.fromJson(
        json['group'] as Map<String, dynamic>? ?? const {},
      ),
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

class SocialRankingEntry {
  const SocialRankingEntry({
    required this.id,
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.points,
    required this.streakDays,
    required this.isCurrentUser,
    required this.isLeader,
    required this.position,
    required this.subtitle,
  });

  final String id;
  final String userId;
  final String name;
  final String? avatarUrl;
  final int points;
  final int streakDays;
  final bool isCurrentUser;
  final bool isLeader;
  final int position;
  final String subtitle;

  factory SocialRankingEntry.fromJson(Map<String, dynamic> json) {
    return SocialRankingEntry(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      points: _toInt(json['points']),
      streakDays: _toInt(json['streakDays']),
      isCurrentUser: json['isCurrentUser'] == true,
      isLeader: json['isLeader'] == true,
      position: _toInt(json['position']),
      subtitle: json['subtitle']?.toString() ?? 'Sequência',
    );
  }
}

class SocialActivityItem {
  const SocialActivityItem({
    required this.id,
    required this.message,
    required this.activityType,
    required this.createdAt,
    required this.metadata,
  });

  final String id;
  final String message;
  final String activityType;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  factory SocialActivityItem.fromJson(Map<String, dynamic> json) {
    return SocialActivityItem(
      id: json['id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      activityType: json['activityType']?.toString() ?? 'activity',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : null,
    );
  }
}

int _toInt(Object? value) {
  if (value is num) {
    return value.round();
  }

  if (value is String) {
    final parsed = num.tryParse(value.replaceAll(',', '.'));
    if (parsed != null) {
      return parsed.round();
    }
  }

  return 0;
}
