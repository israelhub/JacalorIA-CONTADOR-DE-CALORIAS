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
  final objective = _normalizeObjective(input.objective);
  final bmi = _calculateBmi(weightKg, heightCm);
  final metabolicWeightKg = _resolveMetabolicWeightKg(
    weightKg,
    heightCm,
    objective,
  );

  final baseMetabolism = input.sex == 'Feminino'
      ? (10 * metabolicWeightKg) + (6.25 * heightCm) - (5 * age) - 161
      : (10 * metabolicWeightKg) + (6.25 * heightCm) - (5 * age) + 5;

  final activityMultiplier = switch (input.activityLevel) {
    'lightly' => 1.375,
    'moderate' => 1.55,
    'very' => 1.725,
    'extreme' => 1.9,
    _ => 1.2,
  };

  final tdee = baseMetabolism * activityMultiplier;
  final adjustedCalories = _applyObjectiveAdjustment(
    tdee,
    objective,
    bmi,
    input.activityLevel,
  );
  final minimumCalories = _resolveCalorieFloor(input.sex);
  final dailyCalorieGoal = adjustedCalories.round().clamp(minimumCalories, 9999);

  final macros = _resolveMacroGoals(
    dailyCalorieGoal,
    objective,
    metabolicWeightKg,
  );

  return NutritionGoalResult(
    effectiveWeightKg: metabolicWeightKg,
    effectiveHeightCm: heightCm,
    dailyCalorieGoal: dailyCalorieGoal,
    dailyProteinGoal: macros.protein,
    dailyCarbsGoal: macros.carbs,
    dailyFatGoal: macros.fat,
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

double _calculateBmi(double weightKg, double heightCm) {
  final heightM = heightCm / 100;
  if (heightM <= 0) {
    return 0;
  }

  return weightKg / (heightM * heightM);
}

String _normalizeObjective(String objective) {
  return switch (objective) {
    'loseWeight' => 'loseWeight',
    'gainMass' => 'gainMass',
    _ => 'maintainWeight',
  };
}

double _applyObjectiveAdjustment(
  double tdee,
  String objective,
  double bmi,
  String activityLevel,
) {
  if (objective == 'loseWeight') {
    final deficit = _resolveLossDeficitPercent(bmi, activityLevel);
    return tdee * (1 - deficit);
  }

  if (objective == 'gainMass') {
    final surplus = _resolveGainSurplusPercent(bmi, activityLevel);
    return tdee * (1 + surplus);
  }

  return tdee;
}

double _resolveLossDeficitPercent(double bmi, String activityLevel) {
  var percent = 0.2;

  if (bmi >= 40) {
    percent = 0.3;
  } else if (bmi >= 35) {
    percent = 0.27;
  } else if (bmi >= 30) {
    percent = 0.25;
  } else if (bmi >= 27) {
    percent = 0.22;
  } else {
    percent = 0.18;
  }

  if (activityLevel == 'very' || activityLevel == 'extreme') {
    percent -= 0.02;
  }

  return percent.clamp(0.15, 0.3);
}

double _resolveGainSurplusPercent(double bmi, String activityLevel) {
  var percent = 0.1;

  if (bmi < 18.5) {
    percent = 0.2;
  } else if (bmi < 22) {
    percent = 0.15;
  } else if (bmi < 25) {
    percent = 0.12;
  }

  if (activityLevel == 'very' || activityLevel == 'extreme') {
    percent += 0.02;
  }

  return percent.clamp(0.08, 0.22);
}

int _resolveCalorieFloor(String sex) {
  return switch (sex.trim().toLowerCase()) {
    'feminino' => 1200,
    'masculino' => 1500,
    _ => 1350,
  };
}

double _resolveMetabolicWeightKg(
  double weightKg,
  double heightCm,
  String objective,
) {
  if (objective != 'loseWeight') {
    return weightKg;
  }

  final heightM = heightCm / 100;
  if (heightM <= 0) {
    return weightKg;
  }

  final bmi = weightKg / (heightM * heightM);
  if (bmi < 30) {
    return weightKg;
  }

  final idealWeightKg = 24.9 * (heightM * heightM);
  final adjustedWeightKg = idealWeightKg + ((weightKg - idealWeightKg) * 0.25);
  if (adjustedWeightKg < idealWeightKg) {
    return idealWeightKg;
  }
  if (adjustedWeightKg > weightKg) {
    return weightKg;
  }

  return adjustedWeightKg;
}

_MacroGoals _resolveMacroGoals(
  int dailyCalories,
  String objective,
  double metabolicWeightKg,
) {
  final minProtein = (metabolicWeightKg * _resolveProteinPerKg(objective)).round();
  final minFat = (metabolicWeightKg * _resolveFatPerKg(objective)).round();

  final distribution = _resolveMacroDistribution(objective);
  var protein = ((dailyCalories * distribution.protein) / 4).round();
  var fat = ((dailyCalories * distribution.fat) / 9).round();

  protein = protein < minProtein ? minProtein : protein;
  fat = fat < minFat ? minFat : fat;

  var carbs = ((dailyCalories - (protein * 4) - (fat * 9)) / 4)
      .round()
      .clamp(0, 9999);

  final minCarbs =
      (metabolicWeightKg * _resolveCarbsPerKgFloor(objective)).round();
  if (carbs < minCarbs) {
    carbs = minCarbs;
  }

  final totalCalories = (protein * 4) + (fat * 9) + (carbs * 4);
  if (totalCalories > dailyCalories) {
    final overflow = totalCalories - dailyCalories;
    final fatReduction = ((overflow / 9).ceil()).clamp(0, fat - minFat);
    fat -= fatReduction;
  }

  final baseCalories = (protein * 4) + (fat * 9);
  carbs = ((dailyCalories - baseCalories) / 4).round().clamp(0, 9999);

  return _MacroGoals(protein: protein, fat: fat, carbs: carbs);
}

double _resolveProteinPerKg(String objective) {
  return switch (objective) {
    'loseWeight' => 2.2,
    'gainMass' => 1.8,
    _ => 1.6,
  };
}

double _resolveFatPerKg(String objective) {
  return objective == 'loseWeight' ? 0.7 : 0.8;
}

double _resolveCarbsPerKgFloor(String objective) {
  return switch (objective) {
    'loseWeight' => 1.5,
    'gainMass' => 2.5,
    _ => 2.0,
  };
}

_MacroDistribution _resolveMacroDistribution(String objective) {
  return switch (objective) {
    'loseWeight' => const _MacroDistribution(protein: 0.35, fat: 0.30),
    'gainMass' => const _MacroDistribution(protein: 0.25, fat: 0.25),
    _ => const _MacroDistribution(protein: 0.25, fat: 0.30),
  };
}

class _MacroDistribution {
  const _MacroDistribution({required this.protein, required this.fat});

  final double protein;
  final double fat;
}

class _MacroGoals {
  const _MacroGoals({
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  final int protein;
  final int fat;
  final int carbs;
}
