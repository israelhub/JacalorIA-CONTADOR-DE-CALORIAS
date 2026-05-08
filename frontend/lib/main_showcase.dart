import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'features/auth/service/auth_service.dart';
import 'features/food_analysis/models/food_analysis_result.dart';
import 'features/food_analysis/models/food_meal_record.dart';
import 'features/home/pages/home_page.dart';
import 'features/home/pages/home_shell_page.dart';
import 'features/home/services/meal_service.dart';
import 'features/missions/models/missions_overview.dart';
import 'features/missions/pages/missions_page.dart';
import 'features/missions/services/missions_service.dart';
import 'features/performance/models/monthly_performance.dart';
import 'features/performance/models/weight_history.dart';
import 'features/performance/pages/performance_page.dart';
import 'features/performance/services/performance_service.dart';
import 'features/social/models/social_group_models.dart';
import 'features/social/pages/social_page.dart';
import 'features/social/services/social_service.dart';
import 'shared/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AuthService.globalToken = 'showcase-token';
  AuthService.globalUser = <String, dynamic>{
    'id': 'showcase-user',
    'name': 'Usuário Jacaloria',
    'hideMissionsGuideMe': false,
    'hideSocialGuideMe': false,
  };
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  runApp(const ShowcaseApp());
}

class ShowcaseApp extends StatelessWidget {
  const ShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jacaloria Showcase',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: HomeShellPage(
        performancePage: PerformancePage(service: _FakePerformanceService()),
        homePage: HomePage(
          mealService: _FakeMealService(),
          authService: _FakeAuthService(),
        ),
        missionsPage: MissionsPage(
          service: const _FakeMissionsService(),
          authService: _FakeAuthService(),
        ),
        socialPage: SocialPage(
          service: _FakeSocialService(),
          authService: _FakeAuthService(),
        ),
      ),
    );
  }
}

class _FakeAuthService extends AuthService {
  @override
  Future<Map<String, dynamic>> fetchProfile() async {
    return <String, dynamic>{
      'id': 'showcase-user',
      'name': 'Usuário Jacaloria',
      'daily_calorie_goal': 2100,
      'hideMissionsGuideMe': false,
      'hideSocialGuideMe': false,
    };
  }

  @override
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> updates) async {
    final profile = await fetchProfile();
    profile.addAll(updates);
    return profile;
  }

  @override
  Future<void> signOut() async {}
}

class _FakeMealService extends MealService {
  @override
  Future<List<FoodMealRecord>> fetchMeals({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return <FoodMealRecord>[
      FoodMealRecord(
        imageBytes: null,
        imageAsset: 'assets/images/smiling green cartoon crocodile@2x.webp',
        imageUrl: null,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        title: 'Café da manhã',
        description: 'Omelete, pão integral e fruta',
        kcalLabel: '520 kcal',
        timeLabel: '08:15',
        calories: 520,
        protein: 32,
        carbs: 48,
        fat: 16,
        items: const <FoodAnalysisItem>[],
      ),
      FoodMealRecord(
        imageBytes: null,
        imageAsset: 'assets/images/smiling green cartoon crocodile@2x.webp',
        imageUrl: null,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        title: 'Almoço',
        description: 'Arroz, frango grelhado e salada',
        kcalLabel: '710 kcal',
        timeLabel: '12:40',
        calories: 710,
        protein: 45,
        carbs: 62,
        fat: 22,
        items: const <FoodAnalysisItem>[],
      ),
    ];
  }
}

class _FakePerformanceService extends PerformanceService {
  @override
  Future<MonthlyPerformance> fetchMonthlyPerformance(DateTime month) async {
    return MonthlyPerformance(
      month: '${month.year}-${month.month.toString().padLeft(2, '0')}',
      streakDays: 9,
      streakMessage: 'Sequência forte esta semana!',
      calendarYear: month.year,
      calendarMonth: month.month,
      daysInMonth: 30,
      calendarDays: const <PerformanceCalendarDay>[
        PerformanceCalendarDay(day: 1, status: PerformanceDayStatus.goalAchieved),
        PerformanceCalendarDay(day: 2, status: PerformanceDayStatus.goalAchieved),
        PerformanceCalendarDay(day: 3, status: PerformanceDayStatus.mealRegistered),
        PerformanceCalendarDay(day: 4, status: PerformanceDayStatus.goalAchieved),
      ],
      metGoalDays: 12,
      elapsedDays: 16,
      registeredDays: 15,
      consistencyPercent: 75,
      avgDailyCalories: 1980,
      weightDeltaKg: -1.4,
      weightDifferenceKg: 1.4,
      weightDirection: 'lost',
      highlightTitle: 'Distribuição de macros equilibrada',
      highlightDescription: 'Proteína consistente e gordura controlada.',
      macroProgress: const <PerformanceMacroProgress>[
        PerformanceMacroProgress(key: 'carbs', label: 'Carboidratos', percent: 76),
        PerformanceMacroProgress(key: 'protein', label: 'Proteínas', percent: 88),
        PerformanceMacroProgress(key: 'fat', label: 'Gorduras', percent: 62),
      ],
    );
  }

  @override
  Future<WeightHistory> fetchWeightHistory({String period = '30', DateTime? startDate, DateTime? endDate}) async {
    return WeightHistory(
      range: WeightHistoryRange(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
        selectedPeriod: period,
      ),
      points: <WeightHistoryPoint>[
        WeightHistoryPoint(date: DateTime.now().subtract(const Duration(days: 30)), weight: 82.4),
        WeightHistoryPoint(date: DateTime.now().subtract(const Duration(days: 20)), weight: 81.6),
        WeightHistoryPoint(date: DateTime.now().subtract(const Duration(days: 10)), weight: 81.2),
        WeightHistoryPoint(date: DateTime.now(), weight: 81.0),
      ],
    );
  }
}

class _FakeMissionsService extends MissionsService {
  const _FakeMissionsService();

  @override
  Future<MissionsOverview> fetchMissions() async {
    return const MissionsOverview(
      gold: 160,
      xp: 420,
      introTitle: 'Missões para manter constância',
      introDescription: 'Complete desafios diários e semanais para ganhar recompensas.',
      sections: <MissionSection>[
        MissionSection(
          id: MissionType.daily,
          title: 'Missões diárias',
          subtitle: 'Renovam à meia-noite',
          missions: <MissionItem>[
            MissionItem(
              id: '1',
              key: 'protein_goal',
              type: MissionType.daily,
              title: 'Bata a meta de proteína',
              description: 'Chegue a 120g de proteína hoje.',
              accent: MissionAccent.action,
              progressCurrent: 94,
              progressTarget: 120,
              progressLabel: '94/120',
              progressPercent: 78,
              rewardGold: 20,
              rewardXp: 40,
            ),
          ],
        ),
      ],
    );
  }
}

class _FakeSocialService extends SocialService {
  @override
  Future<List<SocialGroupSummary>> fetchGroups() async {
    return <SocialGroupSummary>[
      const SocialGroupSummary(
        id: 'group-1',
        name: 'Família Saudável',
        description: 'Desafio coletivo de consistência alimentar.',
        iconKey: 'salad',
        competitionType: 'offensive',
        competitionLabel: 'Sequência',
        durationDays: 7,
        durationDaysLabel: '7 dias',
        memberCount: 5,
        rankPosition: 2,
        points: 48,
        streakDays: 11,
        leaderName: 'Mariana',
        leaderLabel: 'Mariana lidera',
        remainingDays: 3,
        remainingDaysLabel: '3 dias restantes',
        inviteCode: 'JACA123',
        activities: <SocialActivityItem>[],
      ),
    ];
  }

  @override
  Future<SocialFriendsData> fetchFriends() async {
    return const SocialFriendsData(
      inviteCode: 'JACA123',
      friends: <SocialFriend>[
        SocialFriend(
          id: 'f1',
          name: 'Ana',
          avatarUrl: null,
          avatarFrameId: null,
          streakDays: 8,
        ),
        SocialFriend(
          id: 'f2',
          name: 'Bruno',
          avatarUrl: null,
          avatarFrameId: null,
          streakDays: 5,
        ),
      ],
    );
  }
}
