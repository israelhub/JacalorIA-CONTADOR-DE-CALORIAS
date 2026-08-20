import 'package:flutter_test/flutter_test.dart';

import 'package:jacaloria/features/social/models/social_member_daily_meals.dart';

void main() {
  test('SocialMemberDailyMeals.fromJson parses enabled payload', () {
    final data = SocialMemberDailyMeals.fromJson({
      'enabled': true,
      'competitionType': 'goal_average',
      'date': '2026-07-24',
      'startsAt': '2026-07-20',
      'endsAt': '2026-07-24',
      'totalCalories': 850,
      'meals': [
        {
          'id': 'meal-1',
          'title': 'Almoço',
          'description': 'Arroz e feijão',
          'calories': 500,
          'protein': 20,
          'carbs': 60,
          'fat': 10,
          'timeLabel': '12:30',
          'mealType': 'lunch',
          'imageUrl': null,
          'createdAt': '2026-07-24T15:30:00.000Z',
          'analysisItems': [
            {
              'name': 'Arroz',
              'grams': 100,
              'calories': 130,
              'protein': 3,
              'carbs': 28,
              'fat': 0.2,
            },
          ],
        },
      ],
    });

    expect(data.enabled, isTrue);
    expect(data.competitionType, 'goal_average');
    expect(data.date, '2026-07-24');
    expect(data.startsAt, '2026-07-20');
    expect(data.endsAt, '2026-07-24');
    expect(data.totalCalories, 850);
    expect(data.meals, hasLength(1));
    expect(data.meals.first.title, 'Almoço');
    expect(data.meals.first.calories, 500);
    expect(data.meals.first.items, hasLength(1));
    expect(data.meals.first.items.first.name, 'Arroz');
  });

  test('SocialMemberDailyMeals.fromJson parses disabled payload', () {
    final data = SocialMemberDailyMeals.fromJson({
      'enabled': false,
      'competitionType': 'offensive',
      'date': null,
      'startsAt': null,
      'endsAt': null,
      'totalCalories': 0,
      'meals': [],
    });

    expect(data.enabled, isFalse);
    expect(data.meals, isEmpty);
    expect(data.date, isNull);
  });

  test('SocialMemberDailyMeals.fromJson parses private payload', () {
    final data = SocialMemberDailyMeals.fromJson({
      'enabled': true,
      'isPrivate': true,
      'date': '2026-08-15',
      'startsAt': '2026-01-01',
      'endsAt': '2026-08-15',
      'totalCalories': 0,
      'meals': [],
    });

    expect(data.enabled, isTrue);
    expect(data.isPrivate, isTrue);
    expect(data.meals, isEmpty);
  });
}
