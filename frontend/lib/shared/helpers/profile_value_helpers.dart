int readProfileInt(
  Map<String, dynamic>? profile,
  List<String> keys, {
  int fallback = 0,
}) {
  if (profile == null) {
    return fallback;
  }

  for (final key in keys) {
    final value = profile[key];
    if (value is num) {
      return value.round();
    }

    if (value is String) {
      final parsed = num.tryParse(value);
      if (parsed != null) {
        return parsed.round();
      }
    }
  }

  return fallback;
}
