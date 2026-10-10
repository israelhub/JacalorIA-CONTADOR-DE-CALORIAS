import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/home/widgets/home_shell_layout.dart';
import 'package:jacaloria/features/workouts/models/workout_models.dart';
import 'package:jacaloria/features/workouts/pages/workout_routines_page.dart';
import 'package:jacaloria/shared/theme/app_theme.dart';

void main() {
  testWidgets('scroll reserva o inset da navbar do shell', (tester) async {
    const navOverlap = 88.0;

    await tester.pumpWidget(
      MaterialApp(
        home: HomeShellLayout(
          navOverlap: navOverlap,
          child: const WorkoutRoutinesPage(
            routines: [
              WorkoutRoutine(
                id: 'r1',
                name: 'Treino A',
                sortOrder: 1,
                exercises: [],
              ),
            ],
            selectedRoutineId: 'r1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('workout-routine-row-r1')), findsOneWidget);

    final listView = tester.widget<ListView>(find.byType(ListView));
    expect((listView.padding as EdgeInsets).bottom, navOverlap + AppSpacing.xxxl);
  });
}
