import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/shared/widgets/app_select_input_field.dart';

void main() {
  testWidgets('abre menu ancorado e retorna a opcao selecionada', (
    tester,
  ) async {
    var selectedValue = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSelectInputField(
            fieldKey: const ValueKey('select-field'),
            label: 'Sexo',
            hint: 'Selecione seu sexo',
            selectedValue: 'Masculino',
            options: const ['Masculino', 'Feminino'],
            onSelected: (value) {
              selectedValue = value;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('select-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Feminino').last);
    await tester.pumpAndSettle();

    expect(selectedValue, 'Feminino');
  });
}