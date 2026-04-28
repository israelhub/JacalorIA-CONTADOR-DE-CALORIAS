const List<String> _monthNames = <String>[
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

String performanceMonthLabel(DateTime month) {
  return '${_monthNames[month.month - 1]} ${month.year}';
}

String performanceMonthQuery(DateTime month) {
  final monthText = month.month.toString().padLeft(2, '0');
  return '${month.year}-$monthText';
}
