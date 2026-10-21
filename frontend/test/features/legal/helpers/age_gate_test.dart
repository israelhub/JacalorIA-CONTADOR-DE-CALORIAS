import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/legal/helpers/age_gate.dart';
import 'package:jacaloria/features/legal/legal_documents.dart';

void main() {
  test('aceita idade minima exata', () {
    final now = DateTime(2026, 10, 20);
    final birth = DateTime(
      now.year - LegalDocuments.minUserAgeYears,
      now.month,
      now.day,
    );
    final display =
        '${birth.day.toString().padLeft(2, '0')}/'
        '${birth.month.toString().padLeft(2, '0')}/'
        '${birth.year}';
    expect(AgeGate.isAtLeastMinimumAge(display, now: now), isTrue);
  });

  test('rejeita menor que a idade minima', () {
    final now = DateTime(2026, 10, 20);
    final birth = DateTime(
      now.year - LegalDocuments.minUserAgeYears + 1,
      now.month,
      now.day,
    );
    final display =
        '${birth.day.toString().padLeft(2, '0')}/'
        '${birth.month.toString().padLeft(2, '0')}/'
        '${birth.year}';
    expect(AgeGate.isAtLeastMinimumAge(display, now: now), isFalse);
  });
}
