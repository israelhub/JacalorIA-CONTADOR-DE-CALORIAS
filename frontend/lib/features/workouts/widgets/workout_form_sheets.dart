class WorkoutExerciseDraft {
  const WorkoutExerciseDraft({
    required this.name,
    required this.sets,
    required this.reps,
  });

  final String name;
  final int sets;
  final int reps;
}

class WorkoutLoadDraft {
  const WorkoutLoadDraft({required this.weight, required this.recordedAt});

  final double weight;
  final DateTime recordedAt;
}
