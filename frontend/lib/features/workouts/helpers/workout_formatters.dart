String formatWorkoutWeight(double weight) {
  if (weight == weight.roundToDouble()) {
    return weight.toStringAsFixed(0);
  }
  return weight.toStringAsFixed(1).replaceAll('.', ',');
}

String formatWorkoutDate(DateTime date) {
  const months = <String>[
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];
  final day = date.day.toString().padLeft(2, '0');
  return '$day ${months[date.month - 1]}';
}

String formatWorkoutDateLong(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String formatWorkoutDelta(double delta) {
  final abs = formatWorkoutWeight(delta.abs());
  if (delta > 0) {
    return '+$abs kg';
  }
  if (delta < 0) {
    return '-$abs kg';
  }
  return 'mesmo peso';
}

String toWorkoutDateQuery(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String suggestNextRoutineName(Iterable<String> existingNames) {
  const letters = 'ABCDEFGHIJK';
  final used = existingNames.map((name) => name.trim().toLowerCase()).toSet();
  for (final letter in letters.split('')) {
    final candidate = 'Treino $letter';
    if (!used.contains(candidate.toLowerCase())) {
      return candidate;
    }
  }
  return 'Treino ${existingNames.length + 1}';
}
