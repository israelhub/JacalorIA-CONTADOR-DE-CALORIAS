import '../models/workout_models.dart';

DateTime normalizeWorkoutDate(DateTime date) {
  final local = date.toLocal();
  return DateTime(local.year, local.month, local.day);
}

bool isSameWorkoutDate(DateTime first, DateTime second) {
  final a = first.toLocal();
  final b = second.toLocal();
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class WorkoutDayEntry {
  const WorkoutDayEntry({
    required this.routine,
    required this.exercise,
    required this.load,
  });

  final WorkoutRoutine routine;
  final WorkoutExercise exercise;
  final WorkoutLoad load;
}

List<WorkoutDayEntry> workoutEntriesOnDate({
  required List<WorkoutRoutine> routines,
  required DateTime date,
}) {
  final day = normalizeWorkoutDate(date);
  final entries = <WorkoutDayEntry>[];
  for (final routine in routines) {
    for (final exercise in routine.exercises) {
      for (final load in exercise.loads) {
        if (isSameWorkoutDate(load.recordedAt, day)) {
          entries.add(
            WorkoutDayEntry(routine: routine, exercise: exercise, load: load),
          );
          break;
        }
      }
    }
  }
  return entries;
}

List<WorkoutExercise> remainingExercisesOnDate({
  required WorkoutRoutine routine,
  required DateTime date,
}) {
  final day = normalizeWorkoutDate(date);
  return routine.exercises
      .where(
        (exercise) => !exercise.loads.any(
          (load) => isSameWorkoutDate(load.recordedAt, day),
        ),
      )
      .toList();
}

String? routineIdWithLoadOnDate({
  required List<WorkoutRoutine> routines,
  required DateTime date,
}) {
  for (final routine in routines) {
    final hasLoad = routine.exercises.any(
      (exercise) => exercise.loads.any(
        (load) => isSameWorkoutDate(load.recordedAt, date),
      ),
    );
    if (hasLoad) {
      return routine.id;
    }
  }
  return null;
}
