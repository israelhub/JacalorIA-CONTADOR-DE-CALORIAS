import '../../food_analysis/models/food_meal_record.dart';
import '../helpers/social_model_parsers.dart';

class SocialMemberDailyMeals {
  const SocialMemberDailyMeals({
    required this.enabled,
    required this.competitionType,
    required this.date,
    required this.startsAt,
    required this.endsAt,
    required this.totalCalories,
    required this.meals,
    this.dailyCalorieGoal = 2000,
    this.isPrivate = false,
  });

  final bool enabled;
  final bool isPrivate;
  final String competitionType;
  final String? date;
  final String? startsAt;
  final String? endsAt;
  final int totalCalories;
  final int dailyCalorieGoal;
  final List<FoodMealRecord> meals;

  factory SocialMemberDailyMeals.fromJson(Map<String, dynamic> json) {
    return SocialMemberDailyMeals(
      enabled: json['enabled'] == true,
      isPrivate: json['isPrivate'] == true,
      competitionType: json['competitionType']?.toString() ?? '',
      date: json['date']?.toString(),
      startsAt: json['startsAt']?.toString(),
      endsAt: json['endsAt']?.toString(),
      totalCalories: socialToInt(json['totalCalories']),
      dailyCalorieGoal: _goalOrFallback(
        json['dailyCalorieGoal'] ?? json['daily_calorie_goal'],
      ),
      meals: (json['meals'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(FoodMealRecord.fromJson)
          .toList(growable: false),
    );
  }
}

int _goalOrFallback(Object? value) {
  final parsed = socialToInt(value);
  return parsed > 0 ? parsed : 2000;
}
