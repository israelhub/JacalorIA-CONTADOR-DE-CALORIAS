String formatProfileDisplayDate(String value) {
  final parts = value.split('-');
  if (parts.length == 3) {
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  return value;
}

String? toProfileApiDate(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final parts = trimmed.split('/');
  if (parts.length == 3) {
    return '${parts[2]}-${parts[1]}-${parts[0]}';
  }

  return trimmed;
}

/// Formata há quanto tempo a conta existe, sempre em dias.
String formatProfileAccountAge(Object? rawCreatedAt, {DateTime? now}) {
  DateTime? createdAt;
  if (rawCreatedAt is DateTime) {
    createdAt = rawCreatedAt.toLocal();
  } else {
    final raw = rawCreatedAt?.toString().trim() ?? '';
    if (raw.isEmpty) {
      return 'Não informado';
    }
    createdAt = DateTime.tryParse(raw)?.toLocal();
  }

  if (createdAt == null) {
    return 'Não informado';
  }

  final reference = now ?? DateTime.now();
  final createdDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
  final referenceDay = DateTime(reference.year, reference.month, reference.day);
  final days = referenceDay.difference(createdDay).inDays;

  if (days <= 0) {
    return 'Hoje';
  }
  if (days == 1) {
    return '1 dia';
  }
  return '$days dias';
}