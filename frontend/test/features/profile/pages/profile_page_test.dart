import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/profile/pages/profile_page.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('hidrata peso, altura e selecoes do perfil', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const ProfilePage(
          initialProfile: {
            'weight': 78.4,
            'height': '181',
            'weightUnit': 'lb',
            'heightUnit': 'cm',
            'sex': 'Feminino',
            'objective': 'gainMass',
            'activityLevel': 'very',
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('78.4'), findsOneWidget);
    expect(find.textContaining('181'), findsOneWidget);
    expect(find.text('Feminino'), findsOneWidget);
    expect(find.text('Ganhar massa'), findsOneWidget);
    expect(find.text('Muito ativo'), findsOneWidget);
  });
}