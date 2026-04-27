class NutritionGoalInput {
  const NutritionGoalInput({
    required this.weight,
    required this.height,
    required this.age,
    required this.sex,
    required this.objective,
    required this.activityLevel,
    this.weightUnit = 'kg',
    this.heightUnit = 'cm',
  });

  final double weight;
  final double height;
  final int age;
  final String sex;
  final String objective;
  final String activityLevel;
  final String weightUnit;
  final String heightUnit;
}

class NutritionGoalResult {
  const NutritionGoalResult({
    required this.effectiveWeightKg,
    required this.effectiveHeightCm,
    required this.dailyCalorieGoal,
    required this.dailyProteinGoal,
    required this.dailyCarbsGoal,
    required this.dailyFatGoal,
  });

  final double effectiveWeightKg;
  final double effectiveHeightCm;
  final int dailyCalorieGoal;
  final int dailyProteinGoal;
  final int dailyCarbsGoal;
  final int dailyFatGoal;
}

NutritionGoalResult calculateNutritionGoals(NutritionGoalInput input) {
  final weightKg = _toKilograms(input.weight, input.weightUnit);
  final heightCm = _toCentimeters(input.height, input.heightUnit);

  final age = input.age.clamp(0, 150).toInt();
  final baseMetabolism = input.sex == 'Feminino'
      ? (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161
      : (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;

  final activityMultiplier = switch (input.activityLevel) {
    'lightly' => 1.375,
    'moderate' => 1.55,
    'very' => 1.725,
    'extreme' => 1.9,
    _ => 1.2,
  };

  var tdee = baseMetabolism * activityMultiplier;
  if (input.objective == 'loseWeight') {
    tdee -= 500;
  } else if (input.objective == 'gainMass') {
    tdee += 500;
  }

  final dailyCalorieGoal = tdee.round();
  final dailyProteinGoal = (weightKg * 2).round();
  final dailyFatGoal = (weightKg * 1).round();
  final remainingCalories =
      dailyCalorieGoal - (dailyProteinGoal * 4) - (dailyFatGoal * 9);
  final dailyCarbsGoal = (remainingCalories / 4).round().clamp(0, 9999);

  return NutritionGoalResult(
    effectiveWeightKg: weightKg,
    effectiveHeightCm: heightCm,
    dailyCalorieGoal: dailyCalorieGoal,
    dailyProteinGoal: dailyProteinGoal,
    dailyCarbsGoal: dailyCarbsGoal,
    dailyFatGoal: dailyFatGoal,
  );
}

int calculateAgeFromBirthDate(String? value, {DateTime? referenceDate}) {
  final birthDate = _parseBirthDate(value);
  if (birthDate == null) {
    return 25;
  }

  final today = referenceDate ?? DateTime.now();
  var age = today.year - birthDate.year;
  final hadBirthday =
      today.month > birthDate.month ||
      (today.month == birthDate.month && today.day >= birthDate.day);
  if (!hadBirthday) {
    age -= 1;
  }

  return age.clamp(0, 150).toInt();
}

DateTime? _parseBirthDate(String? value) {
  final raw = value?.trim();
  if (raw == null || raw.isEmpty) {
    return null;
  }

  final separator = raw.contains('-')
      ? '-'
      : raw.contains('/')
      ? '/'
      : null;
  if (separator == null) {
    return null;
  }

  final parts = raw.split(separator);
  if (parts.length != 3) {
    return null;
  }

  final firstPart = int.tryParse(parts[0]);
  final secondPart = int.tryParse(parts[1]);
  final thirdPart = int.tryParse(parts[2]);
  if (firstPart == null || secondPart == null || thirdPart == null) {
    return null;
  }

  if (parts[0].length == 4) {
    return DateTime(firstPart, secondPart, thirdPart);
  }

  return DateTime(thirdPart, secondPart, firstPart);
}

double _toKilograms(double value, String unit) {
  return switch (unit.toLowerCase()) {
    'lb' => value * 0.45359237,
    'g' => value / 1000,
    _ => value,
  };
}

double _toCentimeters(double value, String unit) {
  return switch (unit.toLowerCase()) {
    'm' => value * 100,
    'ft' => value * 30.48,
    'in' => value * 2.54,
    _ => value,
  };
}
