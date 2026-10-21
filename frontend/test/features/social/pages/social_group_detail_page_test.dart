import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jacaloria/features/home/widgets/home_weight_quick_edit_button.dart';
import 'package:jacaloria/features/social/models/social_group_models.dart';
import 'package:jacaloria/features/social/pages/social_group_chat_page.dart';
import 'package:jacaloria/features/social/pages/social_group_detail_page.dart';
import 'package:jacaloria/features/social/services/social_service.dart';
import 'package:jacaloria/features/social/widgets/social_activity_item.dart';
import 'package:jacaloria/shared/widgets/app_main_bottom_navigation.dart';

SocialActivityItem _activity(String id, String message) {
  return SocialActivityItem(
    id: id,
    message: message,
    activityType: 'joined',
    createdAt: DateTime(2026, 8, 19, 12),
    metadata: null,
  );
}

SocialGroupDetail _detail({
  List<SocialActivityItem> recentActivities = const [],
  bool hasMoreActivities = false,
}) {
  return SocialGroupDetail(
    group: SocialGroupSummary(
      id: 'group-1',
      name: 'Família Saudável',
      description: 'Bora se cuidar juntos!',
      iconKey: 'salad',
      competitionType: 'offensive',
      competitionLabel: 'Sequência',
      rule: 'Registre as refeições todos os dias.',
      durationDays: 7,
      durationDaysLabel: '7 dias',
      memberCount: 1,
      rankPosition: 1,
      points: 3,
      streakDays: 3,
      leaderName: 'Eu',
      leaderLabel: 'Eu lidera',
      remainingDays: 4,
      remainingDaysLabel: '4 dias restantes',
      inviteCode: 'ABC123',
      activities: const [],
    ),
    ranking: const [],
    recentActivities: recentActivities,
    hasMoreActivities: hasMoreActivities,
  );
}

class _FakeSocialService extends SocialService {
  _FakeSocialService({
    SocialGroupDetail? detail,
    this.activitiesOnExpand = const [],
  }) : detail = detail ?? _detail();

  final SocialGroupDetail detail;
  final List<SocialActivityItem> activitiesOnExpand;
  int fetchActivitiesCalls = 0;

  @override
  Future<SocialGroupDetail> fetchGroup(String groupId) async => detail;

  @override
  Future<List<SocialActivityItem>> fetchGroupActivities(String groupId) async {
    fetchActivitiesCalls += 1;
    return activitiesOnExpand;
  }

  @override
  Future<List<SocialGroupChatMessage>> fetchGroupMessages(
    String groupId, {
    String? after,
    String? before,
    int limit = 80,
  }) async {
    return const [];
  }
}

Widget _groupPage({
  required SocialGroupDetail detail,
  required _FakeSocialService service,
}) {
  return MaterialApp(
    home: SocialGroupDetailPage(
      groupId: 'group-1',
      initialDetail: detail,
      service: service,
    ),
  );
}

Widget _groupInsideShell() {
  return MaterialApp(
    home: Scaffold(
      extendBody: true,
      body: SocialGroupDetailPage(
        groupId: 'group-1',
        initialDetail: _detail(),
        service: _FakeSocialService(),
      ),
      bottomNavigationBar: AppMainBottomNavigation(
        activeTab: AppMainBottomTab.social,
        onCenterActionTap: () {},
      ),
    ),
  );
}

void main() {
  testWidgets('mostra FAB de chat na tela do grupo', (tester) async {
    await tester.pumpWidget(
      _groupPage(detail: _detail(), service: _FakeSocialService()),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('group-chat-fab')), findsOneWidget);
  });

  testWidgets('FAB de chat fica acima da bottom nav', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 34, top: 47);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34, top: 47);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(_groupInsideShell());
    await tester.pump();

    final fab = tester.getRect(find.byKey(const ValueKey('group-chat-fab')));
    final nav = tester.getRect(
      find.byKey(const ValueKey('app-bottom-nav-surface')),
    );

    expect(
      fab.bottom,
      closeTo(nav.top - homeShellFabNavGap, 1.5),
      reason: 'FAB should sit just above the nav. fab=$fab nav=$nav',
    );
  });

  testWidgets('chat abre por cima da bottom nav', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_groupInsideShell());
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('group-chat-fab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SocialGroupChatPage), findsOneWidget);
    expect(find.text('Mensagem'), findsOneWidget);
    expect(find.byKey(const ValueKey('app-bottom-nav-surface')), findsNothing);
  });

  testWidgets('mostra so 3 atividades e expande o restante no toque', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final activities = [
      _activity('a1', 'Ana entrou no grupo'),
      _activity('a2', 'Bruno entrou no grupo'),
      _activity('a3', 'Carla entrou no grupo'),
      _activity('a4', 'Diego entrou no grupo'),
      _activity('a5', 'Eva entrou no grupo'),
    ];
    final detail = _detail(recentActivities: activities);
    final service = _FakeSocialService(detail: detail);

    await tester.pumpWidget(_groupPage(detail: detail, service: service));
    await tester.pump();

    expect(find.byType(SocialActivityItemWidget), findsNWidgets(3));
    expect(find.text('Diego entrou no grupo'), findsNothing);
    expect(find.text('Ver mais'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('group-activities-expand')),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('group-activities-expand')),
    );
    await tester.tap(find.byKey(const ValueKey('group-activities-expand')));
    await tester.pump();

    expect(find.byType(SocialActivityItemWidget), findsNWidgets(5));
    expect(find.text('Eva entrou no grupo'), findsOneWidget);
    expect(find.text('Ver mais'), findsNothing);
    expect(find.byKey(const ValueKey('group-activities-expand')), findsNothing);
    expect(service.fetchActivitiesCalls, 0);
  });

  testWidgets('carrega atividades restantes ao expandir', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final preview = [
      _activity('a1', 'Ana entrou no grupo'),
      _activity('a2', 'Bruno entrou no grupo'),
      _activity('a3', 'Carla entrou no grupo'),
    ];
    final remaining = [
      ...preview,
      _activity('a4', 'Diego entrou no grupo'),
      _activity('a5', 'Eva entrou no grupo'),
    ];
    final detail = _detail(recentActivities: preview);
    final service = _FakeSocialService(
      detail: detail,
      activitiesOnExpand: remaining,
    );

    await tester.pumpWidget(_groupPage(detail: detail, service: service));
    await tester.pump();

    expect(find.byType(SocialActivityItemWidget), findsNWidgets(3));
    expect(find.text('Diego entrou no grupo'), findsNothing);

    await tester.ensureVisible(
      find.byKey(const ValueKey('group-activities-expand')),
    );
    await tester.tap(find.byKey(const ValueKey('group-activities-expand')));
    await tester.pump();
    await tester.pump();

    expect(service.fetchActivitiesCalls, 1);
    expect(find.byType(SocialActivityItemWidget), findsNWidgets(5));
    expect(find.text('Eva entrou no grupo'), findsOneWidget);
    expect(find.byKey(const ValueKey('group-activities-expand')), findsNothing);
  });
}
