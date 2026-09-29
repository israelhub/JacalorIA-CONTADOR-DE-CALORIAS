import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/home/helpers/home_date_helpers.dart';

void main() {
  test('formata a data da home no padrao curto', () {
    expect(formatHomeDateLabel(DateTime(2026, 3, 15)), '15 mar');
  });

  test('resolveMealRecordedAt usa agora quando o dia selecionado e hoje', () {
    final now = DateTime(2026, 8, 15, 14, 30, 10);
    final recordedAt = resolveMealRecordedAt(
      selectedDate: DateTime(2026, 8, 15),
      now: now,
    );

    expect(recordedAt, now);
  });

  test('resolveMealRecordedAt mantem o horario atual em dia anterior', () {
    final now = DateTime(2026, 8, 15, 14, 30, 10);
    final recordedAt = resolveMealRecordedAt(
      selectedDate: DateTime(2026, 8, 14),
      now: now,
    );

    expect(recordedAt, DateTime(2026, 8, 14, 14, 30, 10));
  });
}