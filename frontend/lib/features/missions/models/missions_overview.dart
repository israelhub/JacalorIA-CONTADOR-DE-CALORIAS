enum MissionType { daily, weekly, monthly, weekend }

enum MissionAccent { action, accent, challenge }

const weeklyUpdateWeightMissionKey = 'weekly_update_weight';

enum CheckInDayStatus { claimable, claimed, missed, locked }

enum CheckInRewardKind { gold, blocker, frame, background }

class MissionsOverview {
  const MissionsOverview({
    required this.gold,
    required this.xp,
    this.goldLifetimeEarned = 0,
    this.goldLifetimeSpent = 0,
    this.xpLifetimeEarned = 0,
    this.xpLifetimeSpent = 0,
    required this.introTitle,
    required this.introDescription,
    this.weekendEvent = const WeekendEventInfo(active: false),
    this.checkIn = const CheckInInfo(active: false),
    required this.sections,
  });

  final int gold;
  final int xp;
  final int goldLifetimeEarned;
  final int goldLifetimeSpent;
  final int xpLifetimeEarned;
  final int xpLifetimeSpent;
  final String introTitle;
  final String introDescription;
  final WeekendEventInfo weekendEvent;
  final CheckInInfo checkIn;
  final List<MissionSection> sections;

  factory MissionsOverview.fromJson(Map<String, dynamic> json) {
    final summary =
        (json['summary'] as Map<String, dynamic>? ?? const <String, dynamic>{});
    final intro =
        (json['intro'] as Map<String, dynamic>? ?? const <String, dynamic>{});
    final weekendEventJson =
        json['weekendEvent'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final checkInJson =
        json['checkIn'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final sections = (json['sections'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(MissionSection.fromJson)
        .toList(growable: false);

    return MissionsOverview(
      gold: _asInt(summary['gold']),
      xp: _asInt(summary['xp']),
      goldLifetimeEarned: _asInt(summary['goldLifetimeEarned']),
      goldLifetimeSpent: _asInt(summary['goldLifetimeSpent']),
      xpLifetimeEarned: _asInt(summary['xpLifetimeEarned']),
      xpLifetimeSpent: _asInt(summary['xpLifetimeSpent']),
      introTitle: intro['title'] as String? ?? 'Bem-vindo às Missões!',
      introDescription: intro['description'] as String? ?? '',
      weekendEvent: WeekendEventInfo.fromJson(weekendEventJson),
      checkIn: CheckInInfo.fromJson(checkInJson),
      sections: sections,
    );
  }

  MissionsOverview copyWith({
    int? gold,
    int? xp,
    int? goldLifetimeEarned,
    int? goldLifetimeSpent,
    int? xpLifetimeEarned,
    int? xpLifetimeSpent,
    String? introTitle,
    String? introDescription,
    WeekendEventInfo? weekendEvent,
    CheckInInfo? checkIn,
    List<MissionSection>? sections,
  }) {
    return MissionsOverview(
      gold: gold ?? this.gold,
      xp: xp ?? this.xp,
      goldLifetimeEarned: goldLifetimeEarned ?? this.goldLifetimeEarned,
      goldLifetimeSpent: goldLifetimeSpent ?? this.goldLifetimeSpent,
      xpLifetimeEarned: xpLifetimeEarned ?? this.xpLifetimeEarned,
      xpLifetimeSpent: xpLifetimeSpent ?? this.xpLifetimeSpent,
      introTitle: introTitle ?? this.introTitle,
      introDescription: introDescription ?? this.introDescription,
      weekendEvent: weekendEvent ?? this.weekendEvent,
      checkIn: checkIn ?? this.checkIn,
      sections: sections ?? this.sections,
    );
  }
}

class CheckInInfo {
  const CheckInInfo({
    required this.active,
    this.campaignId = '',
    this.title = 'Recompensas de agosto',
    this.subtitle = 'Ganhe recompensas até o fim de agosto',
    this.endsOnLabel = '',
    this.todayDayKey = '',
    this.canClaimToday = false,
    this.claimedToday = false,
    this.days = const <CheckInDayItem>[],
  });

  final bool active;
  final String campaignId;
  final String title;
  final String subtitle;
  final String endsOnLabel;
  final String todayDayKey;
  final bool canClaimToday;
  final bool claimedToday;
  final List<CheckInDayItem> days;

  factory CheckInInfo.fromJson(Map<String, dynamic> json) {
    final days = (json['days'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(CheckInDayItem.fromJson)
        .toList(growable: false);

    return CheckInInfo(
      active: json['active'] == true,
      campaignId: json['campaignId'] as String? ?? '',
      title: json['title'] as String? ?? 'Recompensas de agosto',
      subtitle:
          json['subtitle'] as String? ??
          'Ganhe recompensas até o fim de agosto',
      endsOnLabel: json['endsOnLabel'] as String? ?? '',
      todayDayKey: json['todayDayKey'] as String? ?? '',
      canClaimToday: json['canClaimToday'] == true,
      claimedToday: json['claimedToday'] == true,
      days: days,
    );
  }
}

class CheckInDayItem {
  const CheckInDayItem({
    required this.dayKey,
    required this.dayIndex,
    required this.label,
    required this.status,
    required this.primaryKind,
    required this.rewardSummary,
    this.rewards = const <CheckInRewardItem>[],
  });

  final String dayKey;
  final int dayIndex;
  final String label;
  final CheckInDayStatus status;
  final CheckInRewardKind primaryKind;
  final String rewardSummary;
  final List<CheckInRewardItem> rewards;

  factory CheckInDayItem.fromJson(Map<String, dynamic> json) {
    final rewards = (json['rewards'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(CheckInRewardItem.fromJson)
        .toList(growable: false);

    return CheckInDayItem(
      dayKey: json['dayKey'] as String? ?? '',
      dayIndex: _asInt(json['dayIndex']),
      label: json['label'] as String? ?? '',
      status: _checkInStatusFromString(json['status'] as String? ?? ''),
      primaryKind: _checkInKindFromString(json['primaryKind'] as String? ?? ''),
      rewardSummary: json['rewardSummary'] as String? ?? '',
      rewards: rewards,
    );
  }
}

class CheckInRewardItem {
  const CheckInRewardItem({
    required this.kind,
    this.amount = 0,
    this.itemKey = '',
    this.quantity = 0,
  });

  final CheckInRewardKind kind;
  final int amount;
  final String itemKey;
  final int quantity;

  factory CheckInRewardItem.fromJson(Map<String, dynamic> json) {
    return CheckInRewardItem(
      kind: _checkInKindFromString(json['kind'] as String? ?? ''),
      amount: _asInt(json['amount']),
      itemKey: json['itemKey'] as String? ?? '',
      quantity: _asInt(json['quantity']),
    );
  }
}

class WeekendEventInfo {
  const WeekendEventInfo({
    required this.active,
    this.title = '',
    this.headline = '',
    this.subtitle = '',
    this.remainingDays = 0,
    this.remainingLabel = '',
  });

  final bool active;
  final String title;
  final String headline;
  final String subtitle;
  final int remainingDays;
  final String remainingLabel;

  factory WeekendEventInfo.fromJson(Map<String, dynamic> json) {
    return WeekendEventInfo(
      active: json['active'] == true,
      title: json['title'] as String? ?? 'Missão do fim de semana',
      headline: json['headline'] as String? ?? 'Que bom ver você de novo!',
      subtitle:
          json['subtitle'] as String? ??
          'Complete o desafio pra ganhar recompensas extras!',
      remainingDays: _asInt(json['remainingDays']),
      remainingLabel: json['remainingLabel'] as String? ?? '',
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

  bool get isCompleted =>
      progressCurrent >= progressTarget && progressTarget > 0;

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
    case 'weekend':
      return MissionType.weekend;
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

CheckInDayStatus _checkInStatusFromString(String value) {
  switch (value) {
    case 'claimable':
      return CheckInDayStatus.claimable;
    case 'claimed':
      return CheckInDayStatus.claimed;
    case 'missed':
      return CheckInDayStatus.missed;
    default:
      return CheckInDayStatus.locked;
  }
}

CheckInRewardKind _checkInKindFromString(String value) {
  switch (value) {
    case 'blocker':
      return CheckInRewardKind.blocker;
    case 'frame':
      return CheckInRewardKind.frame;
    case 'background':
      return CheckInRewardKind.background;
    default:
      return CheckInRewardKind.gold;
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
