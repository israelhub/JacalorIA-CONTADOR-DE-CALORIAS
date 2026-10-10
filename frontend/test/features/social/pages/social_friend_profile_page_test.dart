import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/social/models/social_friend_profile.dart';
import 'package:jacaloria/features/social/models/social_member_daily_meals.dart';
import 'package:jacaloria/features/social/pages/social_friend_profile_page.dart';
import 'package:jacaloria/features/social/services/social_service.dart';

class _FakeSocialService extends SocialService {
  @override
  Future<SocialFriendProfile> fetchFriendProfile(
    String friendUserId, {
    String? groupId,
    String? viaUserId,
  }) async {
    return SocialFriendProfile(
      id: friendUserId,
      name: 'Ana',
      avatarUrl: null,
      avatarFrameId: null,
      avatarBackgroundId: null,
      streakDays: 3,
      longestStreakDays: 5,
      missionsCompleted: 1,
      cosmeticsOwned: 0,
      friendCount: 2,
      totalXp: 100,
      favoriteDish: null,
      preferredPeriod: null,
      birthDate: null,
      objective: null,
      sex: null,
      createdAt: DateTime(2026, 1, 1),
      isFriend: true,
    );
  }

  @override
  Future<SocialMemberDailyMeals> fetchPublicProfileDailyMeals({
    required String userId,
    String? date,
    String? groupId,
    String? viaUserId,
  }) async {
    return const SocialMemberDailyMeals(
      enabled: true,
      competitionType: '',
      date: '2026-09-30',
      startsAt: '2026-01-01',
      endsAt: '2026-09-30',
      totalCalories: 1265,
      dailyCalorieGoal: 2000,
      meals: [],
    );
  }
}

void main() {
  testWidgets('mostra calorias consumidas e a meta', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SocialFriendProfilePage(
          friendId: 'friend-1',
          service: _FakeSocialService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Calorias hoje'), findsNothing);
    expect(find.text('1265/2000 kcal'), findsOneWidget);
  });
}
