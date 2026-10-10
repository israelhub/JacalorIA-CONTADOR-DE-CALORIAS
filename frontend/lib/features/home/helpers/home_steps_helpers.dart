import '../models/home_steps_models.dart';
import 'home_greeting_helpers.dart';

const defaultStepStrideMeters = 0.78;
const minStepStrideMeters = 0.55;
const maxStepStrideMeters = 0.95;
const stepsCaloriesPerKgPerStep = 0.0005;
const minDailyStepsGoal = 1000;
const maxDailyStepsGoal = 50000;
const homeStepsGoalPresets = <int>[5000, 8000, 10000, 12000, 15000];

int clampDailyStepsGoal(int goal) {
  return goal.clamp(minDailyStepsGoal, maxDailyStepsGoal);
}

double resolveStepStrideMeters({num? heightCm}) {
  if (heightCm == null || heightCm <= 0) {
    return defaultStepStrideMeters;
  }
  return ((heightCm / 100) * 0.415).clamp(
    minStepStrideMeters,
    maxStepStrideMeters,
  );
}

double estimateStepsDistanceKm({
  required int steps,
  num? heightCm,
}) {
  if (steps <= 0) {
    return 0;
  }
  final meters = steps * resolveStepStrideMeters(heightCm: heightCm);
  return meters / 1000;
}

int estimateStepsCaloriesKcal({
  required int steps,
  num? weightKg,
}) {
  if (steps <= 0) {
    return 0;
  }
  final weight = (weightKg == null || weightKg <= 0) ? 70.0 : weightKg.toDouble();
  return (steps * weight * stepsCaloriesPerKgPerStep).round();
}

String formatStepsCount(int steps) {
  final text = steps.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final reverseIndex = text.length - i;
    buffer.write(text[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }
  return buffer.toString();
}

String formatStepsDistanceKm(double kilometers) {
  if (kilometers <= 0) {
    return '0 km';
  }
  if (kilometers < 10) {
    return '${kilometers.toStringAsFixed(2).replaceAll('.', ',')} km';
  }
  return '${kilometers.toStringAsFixed(1).replaceAll('.', ',')} km';
}

String formatStepsCalories(int kcal) => '$kcal kcal';

String homeStepsStatusMessage(HomeStepsOverview overview) {
  switch (overview.status) {
    case HomeStepsStatus.ready:
      return overview.sourceLabel ?? 'Passos de hoje';
    case HomeStepsStatus.needsPermission:
      return 'Ative o acesso aos passos';
    case HomeStepsStatus.needsHealthConnect:
      return 'Instale o Health Connect';
    case HomeStepsStatus.unsupported:
      return 'Disponível no app mobile';
    case HomeStepsStatus.unavailable:
      return 'Não foi possível ler os passos';
  }
}

num? readHomeProfileWeightKg(Map<String, dynamic>? profile) {
  final value = readHomeProfileInt(profile, const ['weight', 'weightKg', 'weight_kg']);
  return value > 0 ? value : null;
}

num? readHomeProfileHeightCm(Map<String, dynamic>? profile) {
  final value = readHomeProfileInt(profile, const [
    'height',
    'heightCm',
    'height_cm',
  ]);
  return value > 0 ? value : null;
}
