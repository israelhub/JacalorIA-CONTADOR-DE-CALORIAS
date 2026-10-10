import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/workouts/models/workout_models.dart';

void main() {
  test('monta overview e calcula delta de carga', () {
    final overview = WorkoutOverview.fromJson({
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
              'lastLoad': {
                'id': 'l2',
                'weight': 42.5,
                'recordedAt': '2026-09-22',
              },
              'previousLoad': {
                'id': 'l1',
                'weight': 40,
                'recordedAt': '2026-09-20',
              },
              'loads': [
                {'id': 'l2', 'weight': 42.5, 'recordedAt': '2026-09-22'},
                {'id': 'l1', 'weight': 40, 'recordedAt': '2026-09-20'},
              ],
            },
          ],
        },
      ],
    });

    expect(overview.routines.single.name, 'Treino A');
    expect(overview.routines.single.exercises.single.loadDelta, 2.5);
    expect(
      overview.routines.single.exercises.single.lastLoad?.recordedAt,
      DateTime(2026, 9, 22),
    );
  });

  test('troca o exercicio na overview e atualiza historico', () {
    final overview = WorkoutOverview.fromJson({
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
                {'id': 'l1', 'weight': 40, 'recordedAt': '2026-09-20'},
              ],
            },
          ],
        },
      ],
    });

    final updated = WorkoutExercise.fromJson({
      'id': 'e1',
      'routineId': 'r1',
      'name': 'Supino reto',
      'sets': 4,
      'reps': 10,
      'sortOrder': 1,
      'lastLoad': {'id': 'l2', 'weight': 42.5, 'recordedAt': '2026-09-25'},
      'previousLoad': {'id': 'l1', 'weight': 40, 'recordedAt': '2026-09-20'},
      'loads': [
        {'id': 'l2', 'weight': 42.5, 'recordedAt': '2026-09-25'},
        {'id': 'l1', 'weight': 40, 'recordedAt': '2026-09-20'},
      ],
    });

    final next = overview.replacingExercise(updated);
    final exercise = next.routines.single.exercises.single;
    expect(exercise.lastLoad?.weight, 42.5);
    expect(exercise.loads, hasLength(2));
    expect(exercise.loadDelta, 2.5);
  });
}
