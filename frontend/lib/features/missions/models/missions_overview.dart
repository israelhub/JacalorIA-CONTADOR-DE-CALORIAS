enum MissionType { daily, weekly, monthly }

enum MissionAccent { action, accent, challenge }

class MissionsOverview {
  const MissionsOverview({
    required this.gold,
    required this.xp,
    required this.introTitle,
    required this.introDescription,
    required this.sections,
  });

  final int gold;
  final int xp;
  final String introTitle;
  final String introDescription;
  final List<MissionSection> sections;

  factory MissionsOverview.fromJson(Map<String, dynamic> json) {
    final summary =
        (json['summary'] as Map<String, dynamic>? ?? const <String, dynamic>{});
    final intro =
        (json['intro'] as Map<String, dynamic>? ?? const <String, dynamic>{});
    final sections = (json['sections'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(MissionSection.fromJson)
        .toList(growable: false);

    return MissionsOverview(
      gold: _asInt(summary['gold']),
      xp: _asInt(summary['xp']),
      introTitle: intro['title'] as String? ?? 'Bem-vindo às Missões!',
      introDescription: intro['description'] as String? ?? '',
      sections: sections,
    );
  }
}

class MissionSection {
  const MissionSection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.missions,
  });

  final MissionType id;
  final String title;
  final String subtitle;
  final List<MissionItem> missions;

  factory MissionSection.fromJson(Map<String, dynamic> json) {
    final missions = (json['missions'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(MissionItem.fromJson)
        .toList(growable: false);

    return MissionSection(
      id: _missionTypeFromString(json['id'] as String? ?? ''),
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      missions: missions,
    );
  }
}

class MissionItem {
  const MissionItem({
    required this.id,
    required this.key,
    required this.type,
    required this.title,
    required this.description,
    required this.accent,
    required this.progressCurrent,
    required this.progressTarget,
    required this.progressLabel,
    required this.progressPercent,
    required this.rewardGold,
    required this.rewardXp,
  });

  final String id;
  final String key;
  final MissionType type;
  final String title;
  final String description;
  final MissionAccent accent;
  final int progressCurrent;
  final int progressTarget;
  final String progressLabel;
  final int progressPercent;
  final int rewardGold;
  final int rewardXp;

  bool get isCompleted => progressCurrent >= progressTarget && progressTarget > 0;

  factory MissionItem.fromJson(Map<String, dynamic> json) {
    return MissionItem(
      id: json['id'] as String? ?? '',
      key: json['key'] as String? ?? '',
      type: _missionTypeFromString(json['type'] as String? ?? ''),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      accent: _missionAccentFromString(json['accent'] as String? ?? ''),
      progressCurrent: _asInt(json['progressCurrent']),
      progressTarget: _asInt(json['progressTarget']),
      progressLabel: json['progressLabel'] as String? ?? '0/0',
      progressPercent: _asInt(json['progressPercent']),
      rewardGold: _asInt(json['rewardGold']),
      rewardXp: _asInt(json['rewardXp']),
    );
  }
}

MissionType _missionTypeFromString(String value) {
  switch (value) {
    case 'daily':
      return MissionType.daily;
    case 'weekly':
      return MissionType.weekly;
    default:
      return MissionType.monthly;
  }
}

MissionAccent _missionAccentFromString(String value) {
  switch (value) {
    case 'action':
      return MissionAccent.action;
    case 'accent':
      return MissionAccent.accent;
    default:
      return MissionAccent.challenge;
  }
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.round();
  }

  if (value is String) {
    return int.tryParse(value) ?? 0;
  }

  return 0;
}
