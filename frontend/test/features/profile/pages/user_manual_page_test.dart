import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/profile/pages/user_manual_page.dart';

void main() {
  testWidgets('manual do usuario lista tutoriais e guias', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: UserManualPage()));
    await tester.pumpAndSettle();

    expect(find.text('Manual do usuário'), findsOneWidget);
    expect(find.text('Tutoriais guiados'), findsOneWidget);
    expect(
      find.textContaining('Um passo a passo curto na tela'),
      findsOneWidget,
    );
    expect(find.text('Tour inicial'), findsOneWidget);
    expect(find.text('Água, passos e peso'), findsOneWidget);
    expect(find.text('Guias das páginas'), findsOneWidget);
    expect(
      find.textContaining('Textos didáticos de cada área'),
      findsOneWidget,
    );
    expect(find.text('Missões'), findsOneWidget);
    expect(find.text('Loja'), findsOneWidget);
    expect(find.text('Treino'), findsWidgets);
    expect(find.text('Perfil'), findsWidgets);
    expect(find.text('Central de ajuda'), findsNothing);
  });
}
