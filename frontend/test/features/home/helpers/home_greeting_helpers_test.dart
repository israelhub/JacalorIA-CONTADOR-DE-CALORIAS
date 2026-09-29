import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/home/helpers/home_greeting_helpers.dart';

void main() {
  group('homeGreetingFor', () {
    test('retorna saudação da manhã', () {
      final greeting = homeGreetingFor(DateTime(2026, 4, 24, 8));

      expect(greeting.label, 'Bom dia,');
      expect(greeting.emoji, '☀️');
    });

    test('retorna saudação da tarde', () {
      final greeting = homeGreetingFor(DateTime(2026, 4, 24, 15));

      expect(greeting.label, 'Boa tarde,');
      expect(greeting.emoji, '🌤️');
    });

    test('retorna saudação da noite', () {
      final greeting = homeGreetingFor(DateTime(2026, 4, 24, 22));

      expect(greeting.label, 'Boa noite,');
      expect(greeting.emoji, '🌙');
    });
  });

  group('readHomeProfileInt', () {
    test('lê valores em formatos camelCase e snake_case', () {
      final profile = <String, dynamic>{
        'dailyCalorieGoal': 2689,
        'daily_protein_goal': 140,
      };

      expect(
        readHomeProfileInt(profile, ['daily_calorie_goal', 'dailyCalorieGoal']),
        2689,
      );
      expect(
        readHomeProfileInt(profile, ['daily_protein_goal', 'dailyProteinGoal']),
        140,
      );
    });
  });
}
