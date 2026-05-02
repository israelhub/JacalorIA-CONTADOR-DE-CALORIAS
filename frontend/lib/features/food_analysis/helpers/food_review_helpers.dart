String formatFoodReviewTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String foodReviewMealTitleFromNow([DateTime? now]) {
  return foodMealTitleForHour((now ?? DateTime.now()).hour);
}

String foodMealTitleFromTimeLabel(String timeLabel) {
  final hour = int.tryParse(timeLabel.split(':').first) ?? DateTime.now().hour;
  return foodMealTitleForHour(hour);
}

String foodMealTitleForHour(int hour) {
  if (hour < 11) {
    return 'Café da manhã';
  }

  if (hour < 16) {
    return 'Almoço';
  }

  return 'Jantar';
}

String suggestMealTitle({
  required DateTime recordedAt,
  required List<String> foodNames,
}) {
  final baseTitle = foodMealTitleForHour(recordedAt.hour);
  final normalized = foodNames
      .map((name) => name.trim().toLowerCase())
      .where((name) => name.isNotEmpty)
      .toList(growable: false);

  final lunchKeywords = <String>[
    'arroz',
    'feij',
    'salada',
    'carne',
    'frango',
    'peixe',
    'farofa',
    'vinagrete',
    'macarr',
  ];

  final breakfastKeywords = <String>[
    'pão',
    'pao',
    'ovo',
    'café',
    'cafe',
    'leite',
    'banana',
    'tapioca',
    'iogurte',
    'queijo',
  ];

  final hasLunchProfile = normalized.any(
    (name) => lunchKeywords.any(name.contains),
  );
  final hasBreakfastProfile = normalized.any(
    (name) => breakfastKeywords.any(name.contains),
  );

  if (hasLunchProfile && recordedAt.hour < 16) {
    return 'Almoço';
  }

  if (hasBreakfastProfile && recordedAt.hour < 11) {
    return 'Café da manhã';
  }

  if (hasLunchProfile && baseTitle == 'Café da manhã') {
    return 'Almoço';
  }

  return baseTitle;
}

class FoodMeasurementValue {
  const FoodMeasurementValue(this.grams, this.unit);

  final int grams;
  final String unit;
}

FoodMeasurementValue parseFoodMeasurement(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) {
    return const FoodMeasurementValue(0, 'g');
  }

  final match = RegExp(
    r'^(\d+(?:[\.,]\d+)?)\s*([\p{L}%]+)?$',
    unicode: true,
  ).firstMatch(normalized);

  if (match == null) {
    return FoodMeasurementValue(0, normalized);
  }

  final grams = double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0;
  final unit = (match.group(2)?.trim().isNotEmpty ?? false)
      ? match.group(2)!.trim()
      : 'g';

  return FoodMeasurementValue(grams.round(), unit);
}

class ManualFoodLineValue {
  const ManualFoodLineValue({
    required this.name,
    required this.grams,
    required this.unit,
  });

  final String name;
  final int grams;
  final String unit;
}

List<ManualFoodLineValue> parseManualFoodBlock(String rawText) {
  final lines = rawText.split(RegExp(r'\r?\n'));
  final items = <ManualFoodLineValue>[];

  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (line.isEmpty) {
      continue;
    }

    final match = RegExp(
      r'^(.+?)\s*[-:]\s*(\d+(?:[\.,]\d+)?)\s*([\p{L}%]+)?$',
      unicode: true,
    ).firstMatch(line);

    if (match == null) {
      continue;
    }

    final name = match.group(1)?.trim() ?? '';
    final grams =
        double.tryParse((match.group(2) ?? '0').replaceAll(',', '.'))
            ?.round() ??
        0;
    final unit = (match.group(3)?.trim().isNotEmpty ?? false)
        ? match.group(3)!.trim().toLowerCase()
        : 'g';

    if (name.isEmpty || grams <= 0) {
      continue;
    }

    items.add(ManualFoodLineValue(name: name, grams: grams, unit: unit));
  }

  return items;
}
