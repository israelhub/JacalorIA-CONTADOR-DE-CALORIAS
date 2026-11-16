import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/food_analysis/pages/food_meal_details_page.dart';
import 'package:jacaloria/features/social/models/social_member_daily_meals.dart';
import 'package:jacaloria/features/social/services/social_service.dart';
import 'package:jacaloria/features/social/widgets/social_member_daily_meals_section.dart';

class _FakeSocialService extends SocialService {
  _FakeSocialService(this.data);

  final SocialMemberDailyMeals data;

  @override
  Future<SocialMemberDailyMeals> fetchPublicProfileDailyMeals({
    required String userId,
    String? date,
    String? groupId,
    String? viaUserId,
  }) async {
    return data;
  }
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('mostra refeições do perfil público', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SocialMemberDailyMealsSection(
          memberUserId: 'user-1',
          service: _FakeSocialService(
            SocialMemberDailyMeals.fromJson({
              'enabled': true,
              'date': '2026-08-15',
              'startsAt': '2026-01-01',
              'endsAt': '2026-08-15',
              'totalCalories': 500,
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
                },
              ],
            }),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Refeições'), findsOneWidget);
    expect(find.text('500 kcal no dia'), findsOneWidget);
    expect(find.text('Almoço'), findsOneWidget);
  });

  testWidgets('abre detalhes da análise ao tocar na refeição', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SocialMemberDailyMealsSection(
          memberUserId: 'user-1',
          service: _FakeSocialService(
            SocialMemberDailyMeals.fromJson({
              'enabled': true,
              'date': '2026-08-15',
              'startsAt': '2026-01-01',
              'endsAt': '2026-08-15',
              'totalCalories': 500,
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
            }),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Almoço'));
    await tester.pumpAndSettle();

    expect(find.byType(FoodMealDetailsPage), findsOneWidget);
    expect(find.text('Detalhes da refeição'), findsOneWidget);
    expect(find.text('Arroz'), findsOneWidget);
    expect(find.byTooltip('Editar refeição'), findsNothing);
  });

  testWidgets('oculta refeições quando o perfil está privado', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SocialMemberDailyMealsSection(
          memberUserId: 'user-1',
          service: _FakeSocialService(
            const SocialMemberDailyMeals(
              enabled: false,
              isPrivate: true,
              competitionType: '',
              date: null,
              startsAt: null,
              endsAt: null,
              totalCalories: 0,
              meals: [],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Refeições'), findsNothing);
  });
}
