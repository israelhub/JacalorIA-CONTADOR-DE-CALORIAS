int socialToInt(Object? value) {
  if (value is num) return value.round();
  if (value is String) {
    final parsed = num.tryParse(value.replaceAll(',', '.'));
    if (parsed != null) return parsed.round();
  }
  return 0;
}
