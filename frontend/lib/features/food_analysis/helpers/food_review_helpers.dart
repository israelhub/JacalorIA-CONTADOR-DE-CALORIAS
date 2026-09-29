String formatFoodReviewTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

enum FoodMealType {
  breakfast,
  lunch,
  dinner,
  free,
}

extension FoodMealTypeX on FoodMealType {
  String get apiValue {
    switch (this) {
      case FoodMealType.breakfast:
        return 'breakfast';
      case FoodMealType.lunch:
        return 'lunch';
      case FoodMealType.dinner:
        return 'dinner';
      case FoodMealType.free:
        return 'free';
    }
  }

  String get chipLabel {
    switch (this) {
      case FoodMealType.breakfast:
        return 'Café';
      case FoodMealType.lunch:
        return 'Almoço';
      case FoodMealType.dinner:
        return 'Janta';
      case FoodMealType.free:
        return 'Livre';
    }
  }

  String get displayLabel {
    switch (this) {
      case FoodMealType.free:
        return 'Refeição livre';
      default:
        return chipLabel;
    }
  }

  String get defaultTitle {
    switch (this) {
      case FoodMealType.breakfast:
        return 'Café da manhã';
      case FoodMealType.lunch:
        return 'Almoço';
      case FoodMealType.dinner:
        return 'Jantar';
      case FoodMealType.free:
        return 'Refeição livre';
    }
  }

  bool get countsTowardCompleteMealsMission {
    return this != FoodMealType.free;
  }
}

const Set<String> _defaultMealTitles = {
  'café',
  'café da manhã',
  'cafe',
  'cafe da manha',
  'almoço',
  'almoco',
  'jantar',
  'janta',
  'refeição livre',
  'refeicao livre',
  'livre',
  'refeição',
  'refeicao',
};

FoodMealType foodMealTypeFromApi(String? value) {
  switch ((value ?? '').trim().toLowerCase()) {
    case 'breakfast':
      return FoodMealType.breakfast;
    case 'lunch':
      return FoodMealType.lunch;
    case 'dinner':
      return FoodMealType.dinner;
    default:
      return FoodMealType.free;
  }
}

FoodMealType foodMealTypeFromTitle(String title) {
  final normalized = title.trim().toLowerCase();
  if (normalized.contains('café') || normalized.contains('cafe')) {
    return FoodMealType.breakfast;
  }
  if (normalized.contains('almo')) {
    return FoodMealType.lunch;
  }
  if (normalized.contains('janta')) {
    return FoodMealType.dinner;
  }
  if (normalized.contains('livre')) {
    return FoodMealType.free;
  }
  return FoodMealType.free;
}

FoodMealType foodMealTypeForHour(int hour) {
  if (hour < 11) {
    return FoodMealType.breakfast;
  }
  if (hour < 16) {
    return FoodMealType.lunch;
  }
  return FoodMealType.dinner;
}

FoodMealType suggestMealType({
  required DateTime recordedAt,
  required List<String> foodNames,
  String? titleHint,
}) {
  final title = (titleHint ?? '').trim();
  if (title.isNotEmpty) {
    final fromTitle = foodMealTypeFromTitle(title);
    if (fromTitle != FoodMealType.free ||
        title.toLowerCase().contains('livre')) {
      return fromTitle;
    }
  }

  final suggestedTitle = suggestMealTitle(
    recordedAt: recordedAt,
    foodNames: foodNames,
  );
  return foodMealTypeFromTitle(suggestedTitle);
}

bool isDefaultMealTitle(String title) {
  final normalized = title.trim().toLowerCase();
  if (normalized.isEmpty) {
    return true;
  }
  return _defaultMealTitles.contains(normalized);
}

String foodReviewMealTitleFromNow([DateTime? now]) {
  return foodMealTitleForHour((now ?? DateTime.now()).toLocal().hour);
}

String foodMealTitleFromTimeLabel(String timeLabel) {
  final hour = int.tryParse(timeLabel.split(':').first) ?? DateTime.now().hour;
  return foodMealTitleForHour(hour);
}

String foodMealTitleForHour(int hour) {
  return foodMealTypeForHour(hour).defaultTitle;
}

String suggestMealTitle({
  required DateTime recordedAt,
  required List<String> foodNames,
}) {
  final localHour = recordedAt.toLocal().hour;
  final baseTitle = foodMealTitleForHour(localHour);
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

  if (hasLunchProfile && localHour < 16) {
    return FoodMealType.lunch.defaultTitle;
  }

  if (hasBreakfastProfile && localHour < 11) {
    return FoodMealType.breakfast.defaultTitle;
  }

  if (hasLunchProfile && baseTitle == FoodMealType.breakfast.defaultTitle) {
    return FoodMealType.lunch.defaultTitle;
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
