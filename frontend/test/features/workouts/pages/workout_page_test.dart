import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/workouts/helpers/workout_formatters.dart';
import 'package:jacaloria/features/workouts/models/workout_models.dart';
import 'package:jacaloria/features/workouts/pages/workout_exercise_details_page.dart';
import 'package:jacaloria/features/workouts/pages/workout_exercise_form_page.dart';
import 'package:jacaloria/features/workouts/pages/workout_import_page.dart';
import 'package:jacaloria/features/workouts/pages/workout_page.dart';
import 'package:jacaloria/features/workouts/pages/workout_routine_name_page.dart';
import 'package:jacaloria/features/workouts/pages/workout_routines_page.dart';
import 'package:jacaloria/features/workouts/services/workout_service.dart';
import 'package:jacaloria/features/workouts/widgets/workout_exercise_card.dart';
import 'package:jacaloria/shared/widgets/app_main_bottom_navigation.dart';

class _FakeWorkoutService extends WorkoutService {
  _FakeWorkoutService(this.overview);

  final WorkoutOverview overview;

  @override
  Future<WorkoutOverview> fetchWorkouts() async => overview;
}

Widget _wrap(Widget child) => MaterialApp(home: child);

WorkoutOverview _filledOverview({required DateTime loadDate}) {
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
            'lastLoad': {
              'id': 'l1',
              'weight': 40,
              'recordedAt': toWorkoutDateQuery(loadDate),
            },
            'loads': [
              {
                'id': 'l1',
                'weight': 40,
                'recordedAt': toWorkoutDateQuery(loadDate),
              },
            ],
          },
        ],
      },
    ],
  });
}

void main() {
  testWidgets('nao renderiza bottom navigation local', (tester) async {
    await tester.pumpWidget(
      _wrap(
        WorkoutPage(
          service: _FakeWorkoutService(const WorkoutOverview(routines: [])),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppMainBottomNavigation), findsNothing);
  });

  testWidgets('mostra estado vazio com importacao', (tester) async {
    await tester.pumpWidget(
      _wrap(
        WorkoutPage(
          service: _FakeWorkoutService(const WorkoutOverview(routines: [])),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fichas'), findsWidgets);
    expect(find.text('Trazer fichas com IA'), findsOneWidget);
    expect(find.text('Seus treinos, do seu jeito'), findsOneWidget);
    expect(find.text('Criar meu primeiro treino'), findsOneWidget);
    expect(find.text('Trazer do bloco de notas'), findsNothing);
  });

  testWidgets('mostra so as fichas para criar o treino', (tester) async {
    final today = DateTime.now();
    await tester.pumpWidget(
      _wrap(
        WorkoutPage(
          service: _FakeWorkoutService(_filledOverview(loadDate: today)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Treino do dia'), findsNothing);
    expect(find.text('Fichas'), findsWidgets);
    expect(find.text('Treinos'), findsNothing);
    expect(find.text('Trazer fichas com IA'), findsOneWidget);
    expect(find.text('Treino A'), findsOneWidget);
    expect(find.text('Supino reto'), findsWidgets);
    expect(find.text('4 × 10'), findsOneWidget);
    expect(find.text('40 kg'), findsOneWidget);
    expect(find.text('Segure um treino para editar'), findsNothing);
    expect(find.text('Adicionar exercício'), findsOneWidget);
    expect(find.byKey(const ValueKey('workout-routine-menu')), findsNothing);
    expect(
      find.byKey(const ValueKey('workout-routines-folder')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('workout-routine-chip-Treino A')),
      findsOneWidget,
    );
    expect(find.text('Novo'), findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey('workout-add-exercise'))).height,
      tester.getSize(find.byType(WorkoutExerciseCard)).height,
    );
    expect(find.text('Trazer do bloco de notas'), findsNothing);
  });

  testWidgets('abre detalhes do exercicio ao tocar no card', (tester) async {
    await tester.pumpWidget(
      _wrap(
        WorkoutPage(
          service: _FakeWorkoutService(
            _filledOverview(loadDate: DateTime(2026, 9, 20)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('20 set'), findsNothing);
    expect(find.text('Histórico'), findsNothing);

    await tester.tap(find.text('Supino reto'));
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutExerciseDetailsPage), findsOneWidget);
    expect(find.text('Detalhes exercício'), findsOneWidget);
    expect(find.text('Evolução da carga'), findsOneWidget);
    expect(find.text('1m'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Histórico'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('Histórico'), findsOneWidget);
    expect(find.text('Adicionar carga'), findsOneWidget);
    expect(find.text('20/09/2026'), findsOneWidget);
  });

  testWidgets('abre pagina ao trazer fichas com IA', (tester) async {
    await tester.pumpWidget(
      _wrap(
        WorkoutPage(
          service: _FakeWorkoutService(const WorkoutOverview(routines: [])),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Trazer fichas com IA'));
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutImportPage), findsOneWidget);
    expect(find.text('Organizar com a IA'), findsOneWidget);
  });

  testWidgets('abre pagina ao criar novo treino', (tester) async {
    await tester.pumpWidget(
      _wrap(
        WorkoutPage(
          service: _FakeWorkoutService(const WorkoutOverview(routines: [])),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Criar meu primeiro treino'));
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutRoutineNamePage), findsOneWidget);
    expect(find.text('Criar treino'), findsOneWidget);
  });

  testWidgets('abre pasta com treinos em linhas', (tester) async {
    await tester.pumpWidget(
      _wrap(
        WorkoutPage(
          service: _FakeWorkoutService(
            _filledOverview(loadDate: DateTime.now()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('workout-routines-folder')));
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutRoutinesPage), findsOneWidget);
    expect(find.text('Fichas'), findsWidgets);
    expect(
      find.byKey(const ValueKey('workout-routine-row-r1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('workout-routine-edit-Treino A')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('workout-routine-delete-Treino A')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('workout-routine-row-add')),
      findsOneWidget,
    );
  });

  testWidgets('abre pagina ao adicionar exercicio', (tester) async {
    await tester.pumpWidget(
      _wrap(
        WorkoutPage(
          service: _FakeWorkoutService(
            _filledOverview(loadDate: DateTime.now()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('workout-add-exercise')));
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutExerciseFormPage), findsOneWidget);
    expect(find.text('Adicionar'), findsOneWidget);
  });
}
