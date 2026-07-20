import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jacaloria/features/social/models/social_group_models.dart';
import 'package:jacaloria/features/social/widgets/social_ranking_item.dart';

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
  testWidgets('mostra posicao e metrica de sequencia por padrao', (tester) async {
    await tester.pumpWidget(
      _wrap(SocialRankingItem(entry: _entryForPosition(1))),
    );

    expect(find.text('1'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Sequência'), findsOneWidget);
    expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
  });

  testWidgets('mostra metas batidas no modo meta diaria', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SocialRankingItem(
          entry: _entryForPosition(2),
          competitionType: 'daily_goal',
        ),
      ),
    );

    expect(find.text('2'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
    expect(find.text('Metas'), findsOneWidget);
    expect(find.byIcon(Icons.flag_rounded), findsOneWidget);
  });

  testWidgets('mostra distancia da meta no modo media de meta', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SocialRankingItem(
          entry: _entryForPosition(1),
          competitionType: 'goal_average',
        ),
      ),
    );

    expect(find.text('1'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
    expect(find.text('da meta'), findsOneWidget);
    expect(find.byIcon(Icons.track_changes_rounded), findsOneWidget);
  });

  testWidgets('mostra sem dados quando nao ha media registrada', (tester) async {
    final entry = SocialRankingEntry(
      id: 'ranking-empty',
      userId: 'user-empty',
      name: 'Sem registro',
      avatarUrl: null,
      avatarFrameId: null,
      points: -1,
      streakDays: 0,
      isCurrentUser: false,
      isLeader: false,
      position: 3,
      subtitle: '',
    );

    await tester.pumpWidget(
      _wrap(
        SocialRankingItem(
          entry: entry,
          competitionType: 'goal_average',
        ),
      ),
    );

    expect(find.text('—'), findsOneWidget);
    expect(find.text('sem dados'), findsOneWidget);
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
