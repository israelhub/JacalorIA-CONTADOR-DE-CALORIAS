String formatHomeDateLabel(DateTime date) {
  const monthLabels = <int, String>{
    1: 'jan',
    2: 'fev',
    3: 'mar',
    4: 'abr',
    5: 'mai',
    6: 'jun',
    7: 'jul',
    8: 'ago',
    9: 'set',
    10: 'out',
    11: 'nov',
    12: 'dez',
  };

  final day = date.day.toString().padLeft(2, '0');
  return '$day ${monthLabels[date.month] ?? 'jan'}';
}

DateTime normalizeHomeDate(DateTime date) {
  final localDate = date.toLocal();
  return DateTime(localDate.year, localDate.month, localDate.day);
}

bool isSameHomeDate(DateTime first, DateTime second) {
  final firstLocal = first.toLocal();
  final secondLocal = second.toLocal();

  return firstLocal.year == secondLocal.year &&
      firstLocal.month == secondLocal.month &&
      firstLocal.day == secondLocal.day;
}
