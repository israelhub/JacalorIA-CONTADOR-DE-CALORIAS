import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/workouts/helpers/workout_day_helpers.dart';
import 'package:jacaloria/features/workouts/models/workout_models.dart';

WorkoutOverview _overview() {
  return WorkoutOverview.fromJson({
    'routines': [
      {
        'id': 'r1',
        'name': 'Treino A',
        'sortOrder': 1,
        'exercises': [
          {
            'id': 'e1',
            'routineId': 'r1',
            'name': 'Supino reto',
            'sets': 4,
            'reps': 10,
            'sortOrder': 1,
            'loads': [
              {'id': 'l1', 'weight': 40, 'recordedAt': '2026-09-25'},
            ],
          },
          {
            'id': 'e2',
            'routineId': 'r1',
            'name': 'Crucifixo',
            'sets': 3,
            'reps': 12,
            'sortOrder': 2,
            'loads': <Map<String, Object>>[],
          },
        ],
      },
    ],
  });
}

void main() {
  test('lista so o que foi registrado no dia', () {
    final overview = _overview();
    final entries = workoutEntriesOnDate(
      routines: overview.routines,
      date: DateTime(2026, 9, 25),
    );

    expect(entries, hasLength(1));
    expect(entries.single.exercise.name, 'Supino reto');
    expect(entries.single.load.weight, 40);
    expect(
      workoutEntriesOnDate(
        routines: overview.routines,
        date: DateTime(2026, 9, 24),
      ),
      isEmpty,
    );
  });

  test('restantes sao os exercicios sem carga naquele dia', () {
    final remaining = remainingExercisesOnDate(
      routine: _overview().routines.single,
      date: DateTime(2026, 9, 25),
    );

    expect(remaining.map((item) => item.name), ['Crucifixo']);
  });
}
