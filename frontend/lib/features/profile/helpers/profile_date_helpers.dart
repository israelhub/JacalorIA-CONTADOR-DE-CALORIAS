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