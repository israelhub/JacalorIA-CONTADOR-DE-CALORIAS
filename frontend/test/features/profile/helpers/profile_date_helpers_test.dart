import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/profile/helpers/profile_date_helpers.dart';

void main() {
  test('formata a data de exibicao do perfil', () {
    expect(formatProfileDisplayDate('2026-03-15'), '15/03/2026');
  });

  test('converte a data do perfil para api', () {
    expect(toProfileApiDate('15/03/2026'), '2026-03-15');
  });
}