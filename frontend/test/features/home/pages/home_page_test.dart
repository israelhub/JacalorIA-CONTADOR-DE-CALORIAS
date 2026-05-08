import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/auth/service/auth_service.dart';
import 'package:jacaloria/features/food_analysis/models/food_meal_record.dart';
import 'package:jacaloria/features/food_analysis/models/food_analysis_result.dart';
import 'package:jacaloria/features/home/pages/home_page.dart';
import 'package:jacaloria/features/home/services/meal_service.dart';
import 'package:jacaloria/shared/widgets/app_main_bottom_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeMealService extends MealService {
  _FakeMealService(this.meals);

  final List<FoodMealRecord> meals;

  @override
  Future<List<FoodMealRecord>> fetchMeals({
    DateTime? startDate,
    DateTime? endDate,
  }) async => meals;
}

class _FakeAuthService extends AuthService {
  @override
  Future<Map<String, dynamic>> fetchProfile() async {
    return <String, dynamic>{'id': 'user-test', 'name': 'Usuário Teste'};
  }

  @override
  Future<void> signOut() async {}
}

Widget _wrap(Widget child) => MaterialApp(home: child);

Future<void> _pumpHomePage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    _wrap(
      HomePage(
        mealService: _FakeMealService(const <FoodMealRecord>[]),
        authService: _FakeAuthService(),
      ),
    ),
  );
}

FoodMealRecord _meal(String title, DateTime createdAt) {
  return FoodMealRecord(
    imageBytes: null,
    imageAsset: null,
    imageUrl: null,
    createdAt: createdAt,
    title: title,
    description: title,
    kcalLabel: '100 kcal',
    timeLabel: '12:00',
    calories: 100,
    protein: 10,
    carbs: 10,
    fat: 10,
    items: const <FoodAnalysisItem>[],
  );
}

void main() {
  group('HomePage', () {
    setUp(() async {
      AuthService.globalToken = 'test-token';
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    tearDown(() {
      AuthService.globalToken = null;
      AuthService.globalUser = null;
    });

    testWidgets('nao renderiza bottom navigation local', (tester) async {
      await _pumpHomePage(tester);
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(AppMainBottomNavigation), findsNothing);
    });

    testWidgets('filtra as refeicoes pela data selecionada', (tester) async {
      tester.view.physicalSize = const Size(412, 917);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          HomePage(
            mealService: _FakeMealService(<FoodMealRecord>[
              _meal('Almoco do dia 2', DateTime(2026, 4, 2, 12)),
              _meal('Jantar do dia 3', DateTime(2026, 4, 3, 19)),
            ]),
            authService: _FakeAuthService(),
            initialSelectedDate: DateTime(2026, 4, 2),
          ),
        ),
      );

      final firstMealCard = find.byKey(const ValueKey('home-meal-card-0'));
      for (var i = 0; i < 120 && firstMealCard.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(firstMealCard, findsOneWidget);
      expect(find.byKey(const ValueKey('home-meal-card-1')), findsNothing);
      expect(find.text('Jantar do dia 3'), findsNothing);
      expect(find.text('02 abr'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('home-calorie-ring-value'))).data,
        '100',
      );
    });
  });
}
