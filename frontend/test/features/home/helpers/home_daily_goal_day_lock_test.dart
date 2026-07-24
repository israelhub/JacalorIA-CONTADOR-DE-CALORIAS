import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jacaloria/features/home/helpers/home_daily_goal_day_lock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('resolveHomeDailyGoalDaySnapshot', () {
    test('congela meta e objetivo na primeira leitura do dia', () async {
      final snapshot = await resolveHomeDailyGoalDaySnapshot(
        profile: {
          'id': 'user-1',
          'dailyCalorieGoal': 2100,
          'objective': 'loseWeight',
        },
        now: DateTime(2026, 7, 24, 10),
      );

      expect(snapshot.dateKey, '2026-07-24');
      expect(snapshot.dailyCalorieGoal, 2100);
      expect(snapshot.objective, 'loseWeight');
    });

    test('mantem snapshot do dia mesmo se o perfil mudar', () async {
      await resolveHomeDailyGoalDaySnapshot(
        profile: {
          'id': 'user-1',
          'dailyCalorieGoal': 2100,
          'objective': 'loseWeight',
        },
        now: DateTime(2026, 7, 24, 10),
      );

      final snapshot = await resolveHomeDailyGoalDaySnapshot(
        profile: {
          'id': 'user-1',
          'dailyCalorieGoal': 2800,
          'objective': 'gainMass',
        },
        now: DateTime(2026, 7, 24, 18),
      );

      expect(snapshot.dailyCalorieGoal, 2100);
      expect(snapshot.objective, 'loseWeight');
    });

    test('renova snapshot quando o dia vira', () async {
      await resolveHomeDailyGoalDaySnapshot(
        profile: {
          'id': 'user-1',
          'dailyCalorieGoal': 2100,
          'objective': 'loseWeight',
        },
        now: DateTime(2026, 7, 24, 10),
      );

      final snapshot = await resolveHomeDailyGoalDaySnapshot(
        profile: {
          'id': 'user-1',
          'dailyCalorieGoal': 2800,
          'objective': 'gainMass',
        },
        now: DateTime(2026, 7, 25, 1),
      );

      expect(snapshot.dateKey, '2026-07-25');
      expect(snapshot.dailyCalorieGoal, 2800);
      expect(snapshot.objective, 'gainMass');
    });
  });

  group('applyHomeDailyGoalDaySnapshot', () {
    test('aplica snapshot apenas para o dia de hoje', () {
      const snapshot = HomeDailyGoalDaySnapshot(
        dateKey: '2026-07-24',
        dailyCalorieGoal: 1900,
        objective: 'maintainWeight',
      );
      final profile = <String, dynamic>{
        'dailyCalorieGoal': 2500,
        'objective': 'gainMass',
      };

      final todayProfile = applyHomeDailyGoalDaySnapshot(
        profile: profile,
        snapshot: snapshot,
        selectedDate: DateTime(2026, 7, 24),
        now: DateTime(2026, 7, 24, 12),
      );
      expect(todayProfile?['dailyCalorieGoal'], 1900);
      expect(todayProfile?['objective'], 'maintainWeight');

      final pastProfile = applyHomeDailyGoalDaySnapshot(
        profile: profile,
        snapshot: snapshot,
        selectedDate: DateTime(2026, 7, 23),
        now: DateTime(2026, 7, 24, 12),
      );
      expect(pastProfile?['dailyCalorieGoal'], 2500);
      expect(pastProfile?['objective'], 'gainMass');
    });
  });
}
