const homeWeekdayLabels = <String>[
  'Seg',
  'Ter',
  'Qua',
  'Qui',
  'Sex',
  'Sáb',
  'Dom',
];

String homeWeekdayLabel(DateTime date) {
  return homeWeekdayLabels[normalizeHomeDate(date).weekday - 1];
}

List<DateTime> homeSelectableWeekDays({
  required DateTime today,
  DateTime? selected,
  int pastDays = 27,
}) {
  final end = normalizeHomeDate(today);
  var start = DateTime(end.year, end.month, end.day - pastDays);
  if (selected != null) {
    final selectedDay = normalizeHomeDate(selected);
    if (selectedDay.isBefore(start)) {
      start = selectedDay;
    }
  }
  final count = end.difference(start).inDays;
  return [
    for (var i = 0; i <= count; i++)
      DateTime(start.year, start.month, start.day + i),
  ];
}

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

DateTime resolveMealRecordedAt({
  required DateTime selectedDate,
  DateTime? now,
}) {
  final reference = (now ?? DateTime.now()).toLocal();
  final day = normalizeHomeDate(selectedDate);
  if (isSameHomeDate(day, reference)) {
    return reference;
  }

  return DateTime(
    day.year,
    day.month,
    day.day,
    reference.hour,
    reference.minute,
    reference.second,
    reference.millisecond,
  );
}
