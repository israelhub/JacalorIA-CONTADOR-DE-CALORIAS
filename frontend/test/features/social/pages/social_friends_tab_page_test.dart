import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jacaloria/features/social/models/social_group_models.dart';
import 'package:jacaloria/features/social/pages/social_friends_tab_page.dart';

SocialFriend _friend() {
  return const SocialFriend(
    id: 'friend-1',
    name: 'Ana Paula',
    avatarUrl: null,
    avatarFrameId: null,
    streakDays: 12,
  );
}

void main() {
  testWidgets('mostra adicionar amigo e lista sem botão de solicitações inline', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 420,
              child: SocialFriendsTabPage(
                friends: [_friend()],
                onAddFriend: () {},
                pendingRequestCount: 3,
                onOpenRequests: () {},
                onOpenFriendProfile: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Adicionar amigo'), findsOneWidget);
    expect(find.byKey(const ValueKey('friend-requests-button')), findsNothing);
    expect(find.text('Seus amigos'), findsOneWidget);
    expect(find.text('Ana Paula'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('oculta solicitações inline mesmo sem pedidos pendentes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 420,
              child: SocialFriendsTabPage(
                friends: [_friend()],
                onAddFriend: () {},
                pendingRequestCount: 0,
                onOpenRequests: () {},
                onOpenFriendProfile: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Adicionar amigo'), findsOneWidget);
    expect(find.byKey(const ValueKey('friend-requests-button')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
