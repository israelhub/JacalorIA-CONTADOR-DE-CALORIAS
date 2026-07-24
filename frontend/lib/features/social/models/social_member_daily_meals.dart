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
  });

  final bool enabled;
  final String competitionType;
  final String? date;
  final String? startsAt;
  final String? endsAt;
  final int totalCalories;
  final List<FoodMealRecord> meals;

  factory SocialMemberDailyMeals.fromJson(Map<String, dynamic> json) {
    return SocialMemberDailyMeals(
      enabled: json['enabled'] == true,
      competitionType: json['competitionType']?.toString() ?? '',
      date: json['date']?.toString(),
      startsAt: json['startsAt']?.toString(),
      endsAt: json['endsAt']?.toString(),
      totalCalories: socialToInt(json['totalCalories']),
      meals: (json['meals'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(FoodMealRecord.fromJson)
          .toList(growable: false),
    );
  }
}
