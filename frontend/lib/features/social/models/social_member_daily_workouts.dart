import '../../workouts/helpers/workout_day_helpers.dart';
import '../../workouts/models/workout_models.dart';
import '../helpers/social_model_parsers.dart';

class SocialMemberDailyWorkouts {
  const SocialMemberDailyWorkouts({
    required this.enabled,
    required this.date,
    required this.startsAt,
    required this.endsAt,
    required this.entries,
    this.isPrivate = false,
  });

  final bool enabled;
  final bool isPrivate;
  final String? date;
  final String? startsAt;
  final String? endsAt;
  final List<SocialMemberDailyWorkoutEntry> entries;

  factory SocialMemberDailyWorkouts.fromJson(Map<String, dynamic> json) {
    return SocialMemberDailyWorkouts(
      enabled: json['enabled'] == true,
      isPrivate: json['isPrivate'] == true,
      date: json['date']?.toString(),
      startsAt: json['startsAt']?.toString(),
      endsAt: json['endsAt']?.toString(),
      entries: (json['entries'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => SocialMemberDailyWorkoutEntry.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false),
    );
  }
}

class SocialMemberDailyWorkoutEntry {
  const SocialMemberDailyWorkoutEntry({
    required this.id,
    required this.weight,
    required this.recordedAt,
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.routineId,
    required this.routineName,
  });

  final String id;
  final double weight;
  final DateTime recordedAt;
  final String exerciseId;
  final String exerciseName;
  final int sets;
  final int reps;
  final String routineId;
  final String routineName;

  factory SocialMemberDailyWorkoutEntry.fromJson(Map<String, dynamic> json) {
    return SocialMemberDailyWorkoutEntry(
      id: json['id']?.toString() ?? '',
      weight: socialToNum(json['weight']).toDouble(),
      recordedAt: _asDate(json['recordedAt'] ?? json['recorded_at']),
      exerciseId:
          json['exerciseId']?.toString() ??
          json['exercise_id']?.toString() ??
          '',
      exerciseName:
          json['exerciseName']?.toString() ??
          json['exercise_name']?.toString() ??
          'Exercício',
      sets: socialToInt(json['sets']),
      reps: socialToInt(json['reps']),
      routineId:
          json['routineId']?.toString() ?? json['routine_id']?.toString() ?? '',
      routineName:
          json['routineName']?.toString() ??
          json['routine_name']?.toString() ??
          'Treino',
    );
  }

  WorkoutDayEntry toDayEntry() {
    return WorkoutDayEntry(
      routine: WorkoutRoutine(
        id: routineId,
        name: routineName,
        sortOrder: 0,
        exercises: const [],
      ),
      exercise: WorkoutExercise(
        id: exerciseId,
        routineId: routineId,
        name: exerciseName,
        sets: sets,
        reps: reps,
        sortOrder: 0,
      ),
      load: WorkoutLoad(id: id, weight: weight, recordedAt: recordedAt),
    );
  }
}

DateTime _asDate(Object? value) {
  final text = value?.toString() ?? '';
  final parts = text.split('T').first.split('-');
  if (parts.length >= 3) {
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? 1;
    final day = int.tryParse(parts[2]) ?? 1;
    return DateTime(year, month, day);
  }
  return DateTime.tryParse(text) ?? DateTime.now();
}
