import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/home/helpers/home_date_helpers.dart';

void main() {
  test('formata a data da home no padrao curto', () {
    expect(formatHomeDateLabel(DateTime(2026, 3, 15)), '15 mar');
  });
}