String formatFoodReviewTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String foodReviewMealTitleFromNow([DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;

  if (hour < 11) {
    return 'Café da manhã';
  }

  if (hour < 16) {
    return 'Almoço';
  }

  return 'Jantar';
}
