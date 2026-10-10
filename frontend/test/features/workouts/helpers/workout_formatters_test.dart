import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/workouts/helpers/workout_formatters.dart';

void main() {
  test('formata peso inteiro e decimal', () {
    expect(formatWorkoutWeight(40), '40');
    expect(formatWorkoutWeight(42.5), '42,5');
  });

  test('sugere o proximo nome de treino livre', () {
    expect(suggestNextRoutineName(const ['Treino A']), 'Treino B');
    expect(suggestNextRoutineName(const ['Treino A', 'Treino B']), 'Treino C');
  });
}
