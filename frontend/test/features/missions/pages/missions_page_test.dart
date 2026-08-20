import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/auth/service/auth_service.dart';
import 'package:jacaloria/features/missions/models/missions_overview.dart';
import 'package:jacaloria/features/missions/pages/missions_page.dart';
import 'package:jacaloria/features/missions/services/missions_service.dart';
import 'package:jacaloria/features/missions/widgets/mission_card.dart';
import 'package:jacaloria/shared/widgets/app_main_bottom_navigation.dart';
import 'package:jacaloria/shared/widgets/app_skeleton.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeMissionsService extends MissionsService {
  const _FakeMissionsService(this.overview);

  final MissionsOverview overview;

  @override
  Future<MissionsOverview> fetchMissions() async => overview;
}

class _FakeErrorMissionsService extends MissionsService {
  const _FakeErrorMissionsService();

  @override
  Future<MissionsOverview> fetchMissions() async {
    throw Exception('Falha ao carregar');
  }
}

class _FakeAuthService extends AuthService {
  @override
  Future<Map<String, dynamic>> fetchProfile({bool forceRefresh = false}) async {
    return <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    return data;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  MissionsOverview buildOverview() {
    return const MissionsOverview(
      gold: 10,
      xp: 25,
      introTitle: 'Bem-vindo às Missões!',
      introDescription: 'Descrição da introdução',
      sections: [
        MissionSection(
          id: MissionType.daily,
          title: 'Missões diárias',
          subtitle: 'Renovam à meia-noite',
          missions: [
            MissionItem(
              id: '1',
              key: 'daily_protein_goal',
              type: MissionType.daily,
              title: 'Atinja sua meta diária de proteínas',
              description: 'Atinja sua meta diária de proteínas',
              accent: MissionAccent.action,
              progressCurrent: 75,
              progressTarget: 120,
              progressLabel: '75/120',
              progressPercent: 63,
              rewardGold: 20,
              rewardXp: 40,
            ),
          ],
        ),
      ],
    );
  }

  MissionsOverview buildLongOverview() {
    return MissionsOverview(
      gold: 10,
      xp: 25,
      introTitle: 'Bem-vindo às Missões!',
      introDescription: 'Descrição da introdução',
      sections: [
        MissionSection(
          id: MissionType.daily,
          title: 'Missões diárias',
          subtitle: 'Renovam à meia-noite',
          missions: [
            for (var index = 1; index <= 8; index += 1)
              MissionItem(
                id: '$index',
                key: 'daily_$index',
                type: MissionType.daily,
                title: 'Missão $index',
                description: 'Descrição $index',
                accent: MissionAccent.action,
                progressCurrent: 0,
                progressTarget: 1,
                progressLabel: '0/1',
                progressPercent: 0,
                rewardGold: 20,
                rewardXp: 40,
              ),
          ],
        ),
      ],
    );
  }

  MissionsOverview buildOverviewWithCompleted() {
    return const MissionsOverview(
      gold: 10,
      xp: 25,
      introTitle: 'Bem-vindo às Missões!',
      introDescription: 'Descrição da introdução',
      sections: [
        MissionSection(
          id: MissionType.daily,
          title: 'Missões diárias',
          subtitle: 'Renovam à meia-noite',
          missions: [
            MissionItem(
              id: '1',
              key: 'daily_done',
              type: MissionType.daily,
              title: 'Missão concluída',
              description: 'Concluída',
              accent: MissionAccent.action,
              progressCurrent: 1,
              progressTarget: 1,
              progressLabel: '1/1',
              progressPercent: 100,
              rewardGold: 20,
              rewardXp: 40,
            ),
            MissionItem(
              id: '2',
              key: 'daily_pending',
              type: MissionType.daily,
              title: 'Missão pendente',
              description: 'Pendente',
              accent: MissionAccent.accent,
              progressCurrent: 0,
              progressTarget: 1,
              progressLabel: '0/1',
              progressPercent: 0,
              rewardGold: 10,
              rewardXp: 15,
            ),
          ],
        ),
      ],
    );
  }

  MissionsOverview buildWeekendOverview() {
    return const MissionsOverview(
      gold: 10,
      xp: 25,
      introTitle: 'Bem-vindo às Missões!',
      introDescription: 'Descrição da introdução',
      weekendEvent: WeekendEventInfo(
        active: true,
        title: 'Missão do fim de semana',
        headline: 'Que bom ver você de novo!',
        subtitle: 'Complete o desafio pra ganhar recompensas extras!',
        remainingDays: 2,
        remainingLabel: '2 DIAS',
      ),
      sections: [
        MissionSection(
          id: MissionType.weekend,
          title: 'Missão do fim de semana',
          subtitle: '2 DIAS',
          missions: [
            MissionItem(
              id: 'w1',
              key: 'weekend_goal_trio',
              type: MissionType.weekend,
              title: 'Bata a meta diária na sexta, sábado e domingo',
              description: 'Bata a meta diária na sexta, sábado e domingo',
              accent: MissionAccent.challenge,
              progressCurrent: 1,
              progressTarget: 3,
              progressLabel: '1/3',
              progressPercent: 33,
              rewardGold: 120,
              rewardXp: 240,
            ),
          ],
        ),
        MissionSection(
          id: MissionType.daily,
          title: 'Missões diárias',
          subtitle: 'Renovam à meia-noite',
          missions: [
            MissionItem(
              id: '1',
              key: 'daily_protein_goal',
              type: MissionType.daily,
              title: 'Atinja sua meta diária de proteínas',
              description: 'Atinja sua meta diária de proteínas',
              accent: MissionAccent.action,
              progressCurrent: 75,
              progressTarget: 120,
              progressLabel: '75/120',
              progressPercent: 63,
              rewardGold: 20,
              rewardXp: 40,
            ),
          ],
        ),
      ],
    );
  }

  MissionsOverview buildCheckInOverview() {
    return const MissionsOverview(
      gold: 10,
      xp: 25,
      introTitle: 'Bem-vindo às Missões!',
      introDescription: 'Descrição da introdução',
      checkIn: CheckInInfo(
        active: true,
        campaignId: 'aug2026',
        title: 'Recompensas de agosto',
        subtitle: 'Ganhe recompensas até o fim de agosto',
        endsOnLabel: 'até 31/08',
        todayDayKey: '2026-08-15',
        canClaimToday: true,
        claimedToday: false,
        days: [
          CheckInDayItem(
            dayKey: '2026-08-14',
            dayIndex: 14,
            label: 'Dia 14',
            status: CheckInDayStatus.missed,
            primaryKind: CheckInRewardKind.gold,
            rewardSummary: '',
          ),
          CheckInDayItem(
            dayKey: '2026-08-15',
            dayIndex: 1,
            label: 'Dia 15',
            status: CheckInDayStatus.claimable,
            primaryKind: CheckInRewardKind.gold,
            rewardSummary: '15 ouro',
            rewards: [
              CheckInRewardItem(kind: CheckInRewardKind.gold, amount: 15),
            ],
          ),
          CheckInDayItem(
            dayKey: '2026-08-16',
            dayIndex: 2,
            label: 'Dia 16',
            status: CheckInDayStatus.locked,
            primaryKind: CheckInRewardKind.gold,
            rewardSummary: '20 ouro',
          ),
        ],
      ),
      sections: [
        MissionSection(
          id: MissionType.daily,
          title: 'Missões diárias',
          subtitle: 'Renovam à meia-noite',
          missions: [
            MissionItem(
              id: '1',
              key: 'daily_protein_goal',
              type: MissionType.daily,
              title: 'Atinja sua meta diária de proteínas',
              description: 'Atinja sua meta diária de proteínas',
              accent: MissionAccent.action,
              progressCurrent: 75,
              progressTarget: 120,
              progressLabel: '75/120',
              progressPercent: 63,
              rewardGold: 20,
              rewardXp: 40,
            ),
          ],
        ),
      ],
    );
  }

  MissionsOverview buildWeeklyWeightOverview() {
    return const MissionsOverview(
      gold: 10,
      xp: 25,
      introTitle: 'Bem-vindo às Missões!',
      introDescription: 'Descrição da introdução',
      sections: [
        MissionSection(
          id: MissionType.weekly,
          title: 'Missões semanais',
          subtitle: 'Renovam toda segunda',
          missions: [
            MissionItem(
              id: 'w-weight',
              key: weeklyUpdateWeightMissionKey,
              type: MissionType.weekly,
              title: 'Atualize o seu peso na semana',
              description: 'Atualize o seu peso na semana',
              accent: MissionAccent.accent,
              progressCurrent: 0,
              progressTarget: 1,
              progressLabel: '0/1',
              progressPercent: 0,
              rewardGold: 30,
              rewardXp: 60,
            ),
          ],
        ),
      ],
    );
  }

  testWidgets('exibe skeleton alinhado ao layout no carregamento inicial', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MissionsPage(
          service: _FakeMissionsService(buildOverview()),
          authService: _FakeAuthService(),
        ),
      ),
    );

    expect(find.byType(AppSkeletonBox), findsWidgets);

    await tester.pumpAndSettle();

    expect(find.byType(AppSkeletonBox), findsNothing);
    expect(find.text('Missões'), findsOneWidget);
  });

  testWidgets('renderiza secoes e cards de missoes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MissionsPage(
          service: _FakeMissionsService(buildOverview()),
          authService: _FakeAuthService(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Missões'), findsOneWidget);
    expect(find.text('Missões diárias'), findsOneWidget);
    expect(find.text('Atinja sua meta diária de proteínas'), findsOneWidget);
    expect(find.text('+20'), findsOneWidget);
    expect(find.text('+40'), findsOneWidget);
  });

  testWidgets('destaca hero permanente com loja e missoes de fim de semana', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MissionsPage(
          service: _FakeMissionsService(buildWeekendOverview()),
          authService: _FakeAuthService(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Missões'), findsOneWidget);
    expect(
      find.text(
        'Troque o ouro das missões na loja por molduras, fundos, figurinhas e proteção de sequência.',
      ),
      findsOneWidget,
    );
    expect(find.text('Abrir loja'), findsOneWidget);
    expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);
    expect(find.text('Missão do fim de semana'), findsWidgets);
    expect(
      find.text('Bata a meta diária na sexta, sábado e domingo'),
      findsOneWidget,
    );
    expect(find.textContaining('2 DIAS'), findsOneWidget);
    expect(find.text('Missões diárias'), findsOneWidget);
  });

  testWidgets('exibe card de check-in com botao de recompensa', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MissionsPage(
          service: _FakeMissionsService(buildCheckInOverview()),
          authService: _FakeAuthService(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Recompensas de agosto'), findsOneWidget);
    expect(find.text('Ganhe recompensas até o fim de agosto'), findsOneWidget);
    expect(find.text('Receber recompensa'), findsOneWidget);
    expect(find.text('Dia 15'), findsOneWidget);
  });

  testWidgets('fecha card de introducao ao tocar no X', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MissionsPage(
          service: _FakeMissionsService(buildOverview()),
          authService: _FakeAuthService(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Bem-vindo às Missões!'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Bem-vindo às Missões!'), findsNothing);
  });

  testWidgets('ordena missoes concluidas para o final e exibe tag', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MissionsPage(
          service: _FakeMissionsService(buildOverviewWithCompleted()),
          authService: _FakeAuthService(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final pendingTitle = find.text('Missão pendente');
    final completedTitle = find.text('Missão concluída');

    expect(pendingTitle, findsOneWidget);
    expect(completedTitle, findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(
      tester.getTopLeft(pendingTitle).dy < tester.getTopLeft(completedTitle).dy,
      isTrue,
    );
  });

  testWidgets('exibe erro e botao de retry quando request falha', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MissionsPage(
          service: const _FakeErrorMissionsService(),
          authService: _FakeAuthService(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Falha ao carregar'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets('abre o editor de peso ao tocar na missao semanal', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MissionsPage(
          service: _FakeMissionsService(buildWeeklyWeightOverview()),
          authService: _FakeAuthService(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Atualize o seu peso na semana'), findsOneWidget);
    expect(find.text('0/1'), findsOneWidget);

    await tester.tap(find.text('Atualize o seu peso na semana'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Atualizar peso'), findsOneWidget);
  });

  testWidgets('ultimo card de missao fica acima da bottom nav', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 34, top: 47);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34, top: 47);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          extendBody: true,
          body: MissionsPage(
            service: _FakeMissionsService(buildLongOverview()),
            authService: _FakeAuthService(),
          ),
          bottomNavigationBar: AppMainBottomNavigation(
            activeTab: AppMainBottomTab.missions,
            onCenterActionTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(RefreshIndicator),
      const Offset(0, -5000),
    );
    await tester.pumpAndSettle();

    final lastCard = tester.getRect(find.byType(MissionCard).last);
    final nav = tester.getRect(
      find.byKey(const ValueKey('app-bottom-nav-surface')),
    );

    expect(
      lastCard.bottom,
      lessThanOrEqualTo(nav.top + 1),
      reason: 'Last mission card should sit above the nav. card=$lastCard nav=$nav',
    );
  });
}
