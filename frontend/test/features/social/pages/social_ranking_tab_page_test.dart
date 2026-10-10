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

Widget _buildPage({
  SocialXpRankingPeriod period = SocialXpRankingPeriod.all,
  List<SocialRankingEntry> ranking = const [],
  bool isLoading = false,
  String? errorMessage,
  int page = 1,
  int totalPages = 0,
  ValueChanged<SocialXpRankingPeriod>? onPeriodChanged,
  ValueChanged<int>? onPageChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: SocialRankingTabPage(
          period: period,
          onPeriodChanged: onPeriodChanged ?? (_) {},
          ranking: ranking,
          isLoading: isLoading,
          errorMessage: errorMessage,
          onRetry: () {},
          onOpenProfile: (_) {},
          page: page,
          totalPages: totalPages,
          onPageChanged: onPageChanged ?? (_) {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('mostra filtros e lista de ranking de XP', (tester) async {
    SocialXpRankingPeriod? changedPeriod;

    await tester.pumpWidget(
      _buildPage(
        onPeriodChanged: (period) => changedPeriod = period,
        ranking: [
          _entry(id: 'u1', position: 1, points: 400),
          _entry(id: 'u2', position: 2, points: 220, isCurrentUser: true),
        ],
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
      _buildPage(ranking: [_entry(id: 'u1', position: 1, points: 400)]),
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
    await tester.pumpWidget(_buildPage(isLoading: true));

    expect(find.byType(AppSkeletonBox), findsWidgets);
    expect(find.text('Ninguém no ranking ainda'), findsNothing);
  });

  testWidgets('mostra empty state quando não há ranking', (tester) async {
    await tester.pumpWidget(
      _buildPage(period: SocialXpRankingPeriod.month),
    );

    expect(find.text('Ninguém no ranking ainda'), findsOneWidget);
  });

  testWidgets('mostra paginação e navega para a próxima página', (
    tester,
  ) async {
    var currentPage = 1;

    await tester.pumpWidget(
      _buildPage(
        ranking: [_entry(id: 'u1', position: 1, points: 400)],
        page: currentPage,
        totalPages: 3,
        onPageChanged: (page) => currentPage = page,
      ),
    );

    expect(find.text('1 / 3'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pump();
    expect(currentPage, 2);
  });
}
