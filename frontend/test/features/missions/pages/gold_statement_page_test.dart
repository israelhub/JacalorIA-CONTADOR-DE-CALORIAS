import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/home/widgets/home_shell_layout.dart';
import 'package:jacaloria/features/missions/pages/gold_statement_page.dart';
import 'package:jacaloria/features/missions/services/missions_service.dart';
import 'package:jacaloria/shared/theme/app_theme.dart';

class _FakeGoldStatementService extends MissionsService {
  _FakeGoldStatementService(this.entries);

  final List<Map<String, dynamic>> entries;

  @override
  Future<List<Map<String, dynamic>>> fetchGoldStatement() async => entries;
}

void main() {
  testWidgets('scroll reserva o inset da navbar do shell', (tester) async {
    const navOverlap = 88.0;

    await tester.pumpWidget(
      MaterialApp(
        home: HomeShellLayout(
          navOverlap: navOverlap,
          child: GoldStatementPage(
            service: _FakeGoldStatementService(const [
              {
                'amountSigned': 20,
                'sourceType': 'mission_reward',
                'createdAt': '2026-10-01T12:00:00.000Z',
              },
              {
                'amountSigned': -15,
                'sourceType': 'avatar_frame_purchase',
                'createdAt': '2026-10-02T12:00:00.000Z',
              },
            ]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recompensa de missão'), findsOneWidget);
    expect(find.text('Compra de moldura'), findsOneWidget);

    final listView = tester.widget<ListView>(find.byType(ListView));
    expect((listView.padding as EdgeInsets).bottom, navOverlap + AppSpacing.xxxl);
  });
}
