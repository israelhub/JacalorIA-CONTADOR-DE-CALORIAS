import '../models/home_steps_models.dart';
import 'home_greeting_helpers.dart';

const defaultStepStrideMeters = 0.78;
const minStepStrideMeters = 0.55;
const maxStepStrideMeters = 0.95;
const stepsCaloriesPerKgPerStep = 0.0005;
const minDailyStepsGoal = 1000;
const maxDailyStepsGoal = 50000;
const homeStepsGoalPresets = <int>[5000, 8000, 10000, 12000, 15000];

const preferredStepsSourceHints = <String>[
  'shealth',
  'samsung.health',
  'samsung.android.health',
  'com.sec.android.app.shealth',
];

class StepsIntervalSample {
  const StepsIntervalSample({
    required this.start,
    required this.end,
    required this.count,
    this.sourceKey = '',
  });

  final DateTime start;
  final DateTime end;
  final int count;
  final String sourceKey;
}

int clampDailyStepsGoal(int goal) {
  return goal.clamp(minDailyStepsGoal, maxDailyStepsGoal);
}

bool isPreferredStepsSource(String? source) {
  if (source == null || source.isEmpty) {
    return false;
  }
  final normalized = source.toLowerCase();
  return preferredStepsSourceHints.any(normalized.contains);
}

int resolveDedupedStepsTotal(
  List<StepsIntervalSample> samples, {
  int? aggregateFallback,
}) {
  final aggregate = (aggregateFallback ?? 0).clamp(0, 500000);
  if (samples.isEmpty) {
    return aggregate;
  }

  final preferred = samples
      .where((sample) => isPreferredStepsSource(sample.sourceKey))
      .toList(growable: false);
  final scoped = preferred.isNotEmpty ? preferred : samples;
  final deduped = _dedupeStepsByMinuteMax(scoped).clamp(0, 500000);

  if (deduped <= 0) {
    return aggregate;
  }

  // Samsung Health (e fontes parecidas) publica telefone+relogio sem
  // deduplicar; o agregado do Health Connect pode ficar ~2x a UI do Samsung.
  if (aggregate <= 0) {
    return deduped;
  }
  return deduped < aggregate ? deduped : aggregate;
}

int _dedupeStepsByMinuteMax(List<StepsIntervalSample> samples) {
  final buckets = <int, double>{};

  for (final sample in samples) {
    if (sample.count <= 0) {
      continue;
    }

    var startMs = sample.start.millisecondsSinceEpoch;
    var endMs = sample.end.millisecondsSinceEpoch;
    if (endMs < startMs) {
      final swap = startMs;
      startMs = endMs;
      endMs = swap;
    }
    if (endMs == startMs) {
      endMs += 1;
    }

    final startMinute = startMs ~/ 60000;
    final endMinute = (endMs - 1) ~/ 60000;
    final minuteSpan = (endMinute - startMinute + 1).clamp(1, 24 * 60);
    final perMinute = sample.count / minuteSpan;

    for (var minute = startMinute; minute <= endMinute; minute++) {
      final current = buckets[minute] ?? 0;
      if (perMinute > current) {
        buckets[minute] = perMinute;
      }
    }
  }

  if (buckets.isEmpty) {
    return 0;
  }

  final total = buckets.values.fold<double>(0, (sum, value) => sum + value);
  return total.round();
}

double? pickStepsMetric({
  required double? measured,
  required double estimate,
}) {
  if (measured == null || measured <= 0) {
    return estimate > 0 ? estimate : null;
  }
  if (estimate <= 0) {
    return measured;
  }
  if (measured > estimate * 1.35) {
    return estimate;
  }
  return measured;
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

double estimateStepsDistanceKm({required int steps, num? heightCm}) {
  if (steps <= 0) {
    return 0;
  }
  final meters = steps * resolveStepStrideMeters(heightCm: heightCm);
  return meters / 1000;
}

int estimateStepsCaloriesKcal({required int steps, num? weightKg}) {
  if (steps <= 0) {
    return 0;
  }
  final weight = (weightKg == null || weightKg <= 0)
      ? 70.0
      : weightKg.toDouble();
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

String formatStepsDistanceKmNumber(double kilometers) {
  if (kilometers <= 0) {
    return '0';
  }
  if (kilometers < 10) {
    return kilometers.toStringAsFixed(2).replaceAll('.', ',');
  }
  return kilometers.toStringAsFixed(1).replaceAll('.', ',');
}

String formatStepsDistanceKm(double kilometers) {
  return '${formatStepsDistanceKmNumber(kilometers)} km';
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
  final value = readHomeProfileInt(profile, const [
    'weight',
    'weightKg',
    'weight_kg',
  ]);
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
