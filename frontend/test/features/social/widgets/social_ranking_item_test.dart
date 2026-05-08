import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jacaloria/features/social/models/social_group_models.dart';
import 'package:jacaloria/features/social/widgets/social_ranking_item.dart';
import 'package:jacaloria/shared/theme/app_theme.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

SocialRankingEntry _entryForPosition(int position) {
  return SocialRankingEntry(
    id: 'ranking-$position',
    userId: 'user-$position',
    name: 'Usuário $position',
    avatarUrl: null,
    avatarFrameId: null,
    points: 100,
    streakDays: 12,
    isCurrentUser: false,
    isLeader: position == 1,
    position: position,
    subtitle: '',
  );
}

void main() {
  testWidgets('mostra trofeu para top 3 com cores corretas', (tester) async {
    final expectedColors = <int, Color>{
      1: AppColors.accent500,
      2: AppColors.socialRankingSilver,
      3: AppColors.socialRankingBronze,
    };

    for (final entry in expectedColors.entries) {
      await tester.pumpWidget(
        _wrap(SocialRankingItem(entry: _entryForPosition(entry.key))),
      );

      final trophyIcon = tester.widget<Icon>(
        find.byIcon(Icons.emoji_events_rounded),
      );

      expect(trophyIcon.color, entry.value);
    }
  });

  testWidgets('mostra numero a partir da quarta posicao', (tester) async {
    await tester.pumpWidget(
      _wrap(SocialRankingItem(entry: _entryForPosition(4))),
    );

    expect(find.byIcon(Icons.emoji_events_rounded), findsNothing);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('nao mostra tag VOCE para usuario atual', (tester) async {
    final currentUserEntry = SocialRankingEntry(
      id: 'ranking-current',
      userId: 'user-current',
      name: 'Usuário atual',
      avatarUrl: null,
      avatarFrameId: null,
      points: 100,
      streakDays: 8,
      isCurrentUser: true,
      isLeader: false,
      position: 2,
      subtitle: '',
    );

    await tester.pumpWidget(_wrap(SocialRankingItem(entry: currentUserEntry)));

    expect(find.text('VOCÊ'), findsNothing);
  });
}
