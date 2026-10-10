enum HomeStepsStatus {
  ready,
  needsPermission,
  needsHealthConnect,
  unsupported,
  unavailable,
}

class HomeStepsOverview {
  const HomeStepsOverview({
    this.steps = 0,
    this.goalSteps = defaultDailyStepsGoal,
    this.distanceKm = 0,
    this.caloriesKcal = 0,
    this.status = HomeStepsStatus.unavailable,
    this.sourceLabel,
  });

  static const defaultDailyStepsGoal = 10000;

  final int steps;
  final int goalSteps;
  final double distanceKm;
  final int caloriesKcal;
  final HomeStepsStatus status;
  final String? sourceLabel;

  int get remainingSteps {
    final remaining = goalSteps - steps;
    return remaining < 0 ? 0 : remaining;
  }

  double get progress {
    if (goalSteps <= 0) {
      return 0;
    }
    return (steps / goalSteps).clamp(0.0, 1.0);
  }

  double get remainingProgress {
    if (goalSteps <= 0) {
      return 0;
    }
    return (remainingSteps / goalSteps).clamp(0.0, 1.0);
  }

  bool get canRequestAccess =>
      status == HomeStepsStatus.needsPermission ||
      status == HomeStepsStatus.needsHealthConnect;

  HomeStepsOverview copyWith({
    int? steps,
    int? goalSteps,
    double? distanceKm,
    int? caloriesKcal,
    HomeStepsStatus? status,
    String? sourceLabel,
  }) {
    return HomeStepsOverview(
      steps: steps ?? this.steps,
      goalSteps: goalSteps ?? this.goalSteps,
      distanceKm: distanceKm ?? this.distanceKm,
      caloriesKcal: caloriesKcal ?? this.caloriesKcal,
      status: status ?? this.status,
      sourceLabel: sourceLabel ?? this.sourceLabel,
    );
  }
}
