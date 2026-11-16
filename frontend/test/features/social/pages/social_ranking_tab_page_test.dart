import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jacaloria/features/social/models/social_group_models.dart';
import 'package:jacaloria/features/social/pages/social_ranking_tab_page.dart';
import 'package:jacaloria/shared/widgets/app_skeleton.dart';

SocialRankingEntry _entry({
  required String id,
  required int position,
  required int points,
  bool isCurrentUser = false,
}) {
  return SocialRankingEntry(
    id: id,
    userId: id,
    name: 'User $position',
    avatarUrl: null,
    avatarFrameId: null,
    points: points,
    streakDays: 0,
    isCurrentUser: isCurrentUser,
    isLeader: false,
    position: position,
    subtitle: isCurrentUser ? 'Você' : '',
  );
}

void main() {
  testWidgets('mostra filtros e lista de ranking de XP', (tester) async {
    SocialXpRankingPeriod? changedPeriod;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SocialRankingTabPage(
              period: SocialXpRankingPeriod.all,
              onPeriodChanged: (period) => changedPeriod = period,
              ranking: [
                _entry(id: 'u1', position: 1, points: 400),
                _entry(id: 'u2', position: 2, points: 220, isCurrentUser: true),
              ],
              isLoading: false,
              errorMessage: null,
              onRetry: () {},
              onOpenProfile: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Ranking de XP'), findsOneWidget);
    expect(find.text('Geral'), findsOneWidget);
    expect(find.text('Mês'), findsNothing);
    expect(find.text('Semana'), findsNothing);
    expect(find.text('User 1'), findsOneWidget);
    expect(find.text('User 2'), findsOneWidget);
    expect(find.text('Você'), findsOneWidget);
    expect(find.text('XP'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('xp-ranking-period-filter')));
    await tester.pumpAndSettle();
    expect(find.text('Mês'), findsOneWidget);
    expect(find.text('Semana'), findsOneWidget);

    await tester.tap(find.text('Semana').last);
    await tester.pumpAndSettle();
    expect(changedPeriod, SocialXpRankingPeriod.week);
    expect(find.text('Mês'), findsNothing);
  });

  testWidgets('fecha o filtro ao tocar fora do menu', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SocialRankingTabPage(
              period: SocialXpRankingPeriod.all,
              onPeriodChanged: (_) {},
              ranking: [_entry(id: 'u1', position: 1, points: 400)],
              isLoading: false,
              errorMessage: null,
              onRetry: () {},
              onOpenProfile: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('xp-ranking-period-filter')));
    await tester.pumpAndSettle();
    expect(find.text('Semana'), findsOneWidget);

    await tester.tapAt(const Offset(12, 12));
    await tester.pumpAndSettle();
    expect(find.text('Semana'), findsNothing);
  });

  testWidgets('mostra skeleton quando o ranking está carregando', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SocialRankingTabPage(
            period: SocialXpRankingPeriod.all,
            onPeriodChanged: (_) {},
            ranking: const [],
            isLoading: true,
            errorMessage: null,
            onRetry: () {},
            onOpenProfile: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(AppSkeletonBox), findsWidgets);
    expect(find.text('Ninguém no ranking ainda'), findsNothing);
  });

  testWidgets('mostra empty state quando não há ranking', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SocialRankingTabPage(
            period: SocialXpRankingPeriod.month,
            onPeriodChanged: (_) {},
            ranking: const [],
            isLoading: false,
            errorMessage: null,
            onRetry: () {},
            onOpenProfile: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Ninguém no ranking ainda'), findsOneWidget);
  });
}
