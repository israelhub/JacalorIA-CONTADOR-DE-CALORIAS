import '../legal_documents.dart';

class AgeGate {
  static DateTime maxBirthDate({DateTime? now}) {
    final reference = now ?? DateTime.now();
    return DateTime(
      reference.year - LegalDocuments.minUserAgeYears,
      reference.month,
      reference.day,
    );
  }

  static DateTime minBirthDate() => DateTime(1900);

  /// [displayDate] no formato dd/MM/yyyy.
  static bool isAtLeastMinimumAge(String displayDate, {DateTime? now}) {
    final parts = displayDate.trim().split('/');
    if (parts.length != 3) {
      return false;
    }
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return false;
    }
    final birth = DateTime(year, month, day);
    if (birth.year != year || birth.month != month || birth.day != day) {
      return false;
    }
    return !birth.isAfter(maxBirthDate(now: now));
  }

  static String minimumAgeMessage() {
    return 'O JacalorIA é destinado a maiores de '
        '${LegalDocuments.minUserAgeYears} anos.';
  }
}
