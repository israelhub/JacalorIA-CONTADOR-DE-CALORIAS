import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/missions/models/missions_overview.dart';
import 'package:jacaloria/features/missions/pages/missions_page.dart';
import 'package:jacaloria/features/missions/services/missions_service.dart';

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

void main() {
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
              title: 'Atinja sua meta de proteínas',
              description: 'Consuma pelo menos 120g de proteína',
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

  testWidgets('renderiza secoes e cards de missoes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MissionsPage(service: _FakeMissionsService(buildOverview())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Missões'), findsOneWidget);
    expect(find.text('Missões diárias'), findsOneWidget);
    expect(find.text('Atinja sua meta de proteínas'), findsOneWidget);
    expect(find.text('+20'), findsOneWidget);
    expect(find.text('+40 XP'), findsOneWidget);
  });

  testWidgets('fecha card de introducao ao tocar no X', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MissionsPage(service: _FakeMissionsService(buildOverview())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Bem-vindo às Missões!'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Bem-vindo às Missões!'), findsNothing);
  });

  testWidgets('exibe erro e botao de retry quando request falha', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MissionsPage(service: _FakeErrorMissionsService()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Falha ao carregar'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}
