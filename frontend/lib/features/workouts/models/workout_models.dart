class WorkoutOverview {
  const WorkoutOverview({required this.routines});

  final List<WorkoutRoutine> routines;

  factory WorkoutOverview.fromJson(Map<String, dynamic> json) {
    final raw = json['routines'];
    final routines = raw is List
        ? raw
              .whereType<Map>()
              .map(
                (item) =>
                    WorkoutRoutine.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
        : <WorkoutRoutine>[];
    return WorkoutOverview(routines: routines);
  }

  WorkoutOverview replacingExercise(WorkoutExercise updated) {
    return WorkoutOverview(
      routines: routines
          .map(
            (routine) => routine.id == updated.routineId
                ? routine.replacingExercise(updated)
                : routine,
          )
          .toList(),
    );
  }
}

class WorkoutRoutine {
  const WorkoutRoutine({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.exercises,
  });

  final String id;
  final String name;
  final int sortOrder;
  final List<WorkoutExercise> exercises;

  factory WorkoutRoutine.fromJson(Map<String, dynamic> json) {
    final raw = json['exercises'];
    return WorkoutRoutine(
      id: json['id'] as String,
      name: json['name'] as String,
      sortOrder: _asInt(json['sortOrder']),
      exercises: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (item) =>
                      WorkoutExercise.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const <WorkoutExercise>[],
    );
  }

  WorkoutRoutine replacingExercise(WorkoutExercise updated) {
    return WorkoutRoutine(
      id: id,
      name: name,
      sortOrder: sortOrder,
      exercises: exercises
          .map((exercise) => exercise.id == updated.id ? updated : exercise)
          .toList(),
    );
  }
}

class WorkoutExercise {
  const WorkoutExercise({
    required this.id,
    required this.routineId,
    required this.name,
    required this.sets,
    required this.reps,
    required this.sortOrder,
    this.lastLoad,
    this.previousLoad,
    this.loads = const <WorkoutLoad>[],
  });

  final String id;
  final String routineId;
  final String name;
  final int sets;
  final int reps;
  final int sortOrder;
  final WorkoutLoad? lastLoad;
  final WorkoutLoad? previousLoad;
  final List<WorkoutLoad> loads;

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    final raw = json['loads'];
    return WorkoutExercise(
      id: json['id'] as String,
      routineId: (json['routineId'] ?? json['routine_id']) as String,
      name: json['name'] as String,
      sets: _asInt(json['sets']),
      reps: _asInt(json['reps']),
      sortOrder: _asInt(json['sortOrder'] ?? json['sort_order']),
      lastLoad: _maybeLoad(json['lastLoad'] ?? json['last_load']),
      previousLoad: _maybeLoad(json['previousLoad'] ?? json['previous_load']),
      loads: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (item) =>
                      WorkoutLoad.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const <WorkoutLoad>[],
    );
  }

  double? get loadDelta {
    final last = lastLoad?.weight;
    final previous = previousLoad?.weight;
    if (last == null || previous == null) {
      return null;
    }
    return last - previous;
  }
}

class WorkoutLoad {
  const WorkoutLoad({
    required this.id,
    required this.weight,
    required this.recordedAt,
  });

  final String id;
  final double weight;
  final DateTime recordedAt;

  factory WorkoutLoad.fromJson(Map<String, dynamic> json) {
    return WorkoutLoad(
      id: json['id'] as String,
      weight: _asDouble(json['weight']),
      recordedAt: _asDate(json['recordedAt'] ?? json['recorded_at']),
    );
  }
}

WorkoutLoad? _maybeLoad(Object? value) {
  if (value is Map) {
    return WorkoutLoad.fromJson(Map<String, dynamic>.from(value));
  }
  return null;
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

DateTime _asDate(Object? value) {
  final text = value.toString();
  final parts = text.split('T').first.split('-');
  if (parts.length >= 3) {
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? 1;
    final day = int.tryParse(parts[2]) ?? 1;
    return DateTime(year, month, day);
  }
  return DateTime.tryParse(text) ?? DateTime.now();
}

double _asDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }
  return 0;
}
