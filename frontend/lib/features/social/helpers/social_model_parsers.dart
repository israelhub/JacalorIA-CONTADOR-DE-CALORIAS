int socialToInt(Object? value) {
  if (value is num) return value.round();
  if (value is String) {
    final parsed = num.tryParse(value.replaceAll(',', '.'));
    if (parsed != null) return parsed.round();
  }
  return 0;
}

num socialToNum(Object? value) {
  if (value is num) return value;
  if (value is String) {
    final parsed = num.tryParse(value.replaceAll(',', '.'));
    if (parsed != null) return parsed;
  }
  return 0;
}

String socialFormatAverageCalories(num value) {
  final rounded = (value * 10).round() / 10;
  if (rounded == rounded.roundToDouble()) {
    return rounded.round().toString();
  }
  return rounded.toStringAsFixed(1);
}
