import 'dart:math';

import '../../features/food_analysis/helpers/food_review_helpers.dart';

/// Horários padrão próximos às refeições comuns no Brasil.
class MealReminderDefaults {
  MealReminderDefaults._();

  static const maxReminders = 6;

  static const breakfastHour = 7;
  static const breakfastMinute = 45;
  static const lunchHour = 11;
  static const lunchMinute = 45;
  static const dinnerHour = 18;
  static const dinnerMinute = 45;

  static const breakfastId = 'breakfast';
  static const lunchId = 'lunch';
  static const dinnerId = 'dinner';
}

class MealReminderConfig {
  const MealReminderConfig({
    required this.id,
    required this.title,
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  final String id;
  final String title;
  final bool enabled;
  final int hour;
  final int minute;

  bool get isBuiltIn =>
      id == MealReminderDefaults.breakfastId ||
      id == MealReminderDefaults.lunchId ||
      id == MealReminderDefaults.dinnerId;

  String get timeLabel {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static MealReminderConfig defaultsForBuiltIn(String id) {
    switch (id) {
      case MealReminderDefaults.breakfastId:
        return const MealReminderConfig(
          id: MealReminderDefaults.breakfastId,
          title: 'Café da manhã',
          enabled: true,
          hour: MealReminderDefaults.breakfastHour,
          minute: MealReminderDefaults.breakfastMinute,
        );
      case MealReminderDefaults.lunchId:
        return const MealReminderConfig(
          id: MealReminderDefaults.lunchId,
          title: 'Almoço',
          enabled: true,
          hour: MealReminderDefaults.lunchHour,
          minute: MealReminderDefaults.lunchMinute,
        );
      case MealReminderDefaults.dinnerId:
        return const MealReminderConfig(
          id: MealReminderDefaults.dinnerId,
          title: 'Jantar',
          enabled: true,
          hour: MealReminderDefaults.dinnerHour,
          minute: MealReminderDefaults.dinnerMinute,
        );
      default:
        return MealReminderConfig(
          id: id,
          title: 'Lembrete',
          enabled: true,
          hour: 15,
          minute: 0,
        );
    }
  }

  /// Cria um lembrete extra com horário sugerido e título amigável.
  factory MealReminderConfig.custom({
    required int hour,
    required int minute,
    String? title,
    String? id,
  }) {
    final suggested = foodMealTypeForHour(hour).defaultTitle;
    return MealReminderConfig(
      id: id ?? 'custom_${DateTime.now().microsecondsSinceEpoch}',
      title: (title ?? suggested).trim().isEmpty
          ? 'Lembrete'
          : (title ?? suggested).trim(),
      enabled: true,
      hour: hour,
      minute: minute,
    );
  }

  MealReminderConfig copyWith({
    String? title,
    bool? enabled,
    int? hour,
    int? minute,
  }) {
    return MealReminderConfig(
      id: id,
      title: title ?? this.title,
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'enabled': enabled,
      'hour': hour,
      'minute': minute,
    };
  }

  factory MealReminderConfig.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString().trim();
    final fallback = id.isEmpty
        ? MealReminderConfig.custom(hour: 15, minute: 0)
        : MealReminderConfig.defaultsForBuiltIn(id);
    return MealReminderConfig(
      id: id.isEmpty ? fallback.id : id,
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : fallback.title,
      enabled: json['enabled'] is bool ? json['enabled'] as bool : true,
      hour: json['hour'] is int ? json['hour'] as int : fallback.hour,
      minute: json['minute'] is int ? json['minute'] as int : fallback.minute,
    );
  }
}

class MealReminderSettings {
  const MealReminderSettings({
    required this.masterEnabled,
    required this.reminders,
  });

  final bool masterEnabled;
  final List<MealReminderConfig> reminders;

  static const maxReminders = MealReminderDefaults.maxReminders;

  bool get canAddMore => reminders.length < maxReminders;

  int get remainingSlots => max(0, maxReminders - reminders.length);

  factory MealReminderSettings.defaults() {
    return MealReminderSettings(
      masterEnabled: true,
      reminders: <MealReminderConfig>[
        MealReminderConfig.defaultsForBuiltIn(
          MealReminderDefaults.breakfastId,
        ),
        MealReminderConfig.defaultsForBuiltIn(MealReminderDefaults.lunchId),
        MealReminderConfig.defaultsForBuiltIn(MealReminderDefaults.dinnerId),
      ],
    );
  }

  MealReminderConfig? byId(String id) {
    for (final reminder in reminders) {
      if (reminder.id == id) {
        return reminder;
      }
    }
    return null;
  }

  MealReminderSettings copyWith({
    bool? masterEnabled,
    List<MealReminderConfig>? reminders,
  }) {
    return MealReminderSettings(
      masterEnabled: masterEnabled ?? this.masterEnabled,
      reminders: reminders ?? this.reminders,
    );
  }

  MealReminderSettings withReminder(MealReminderConfig config) {
    final next = reminders.toList(growable: true);
    final index = next.indexWhere((item) => item.id == config.id);
    if (index >= 0) {
      next[index] = config;
    } else if (next.length < maxReminders) {
      next.add(config);
    }
    return copyWith(reminders: List<MealReminderConfig>.unmodifiable(next));
  }

  MealReminderSettings withoutReminder(String id) {
    return copyWith(
      reminders: List<MealReminderConfig>.unmodifiable(
        reminders.where((item) => item.id != id),
      ),
    );
  }

  /// Adiciona um lembrete se ainda houver vaga (máx. [maxReminders]).
  MealReminderSettings? tryAdd(MealReminderConfig config) {
    if (!canAddMore) {
      return null;
    }
    if (reminders.any((item) => item.id == config.id)) {
      return withReminder(config);
    }
    return copyWith(
      reminders: List<MealReminderConfig>.unmodifiable(
        <MealReminderConfig>[...reminders, config],
      ),
    );
  }
}

/// Textos curtos em pt-BR para cada lembrete.
({String title, String body}) mealReminderCopy(MealReminderConfig config) {
  final normalized = config.title.trim().toLowerCase();
  if (config.id == MealReminderDefaults.breakfastId ||
      normalized.contains('café') ||
      normalized.contains('cafe')) {
    return (
      title: 'Hora do café da manhã',
      body: 'Registre sua refeição no JacalorIA pra não esquecer.',
    );
  }
  if (config.id == MealReminderDefaults.lunchId ||
      normalized.contains('almo')) {
    return (
      title: 'Hora do almoço',
      body: 'Não esqueça de registrar o que comeu no JacalorIA.',
    );
  }
  if (config.id == MealReminderDefaults.dinnerId ||
      normalized.contains('janta')) {
    return (
      title: 'Hora do jantar',
      body: 'Registre o jantar e mantenha o acompanhamento em dia.',
    );
  }
  return (
    title: config.title.trim().isEmpty ? 'Hora de registrar' : config.title,
    body: 'Que tal registrar uma refeição no JacalorIA?',
  );
}

/// IDs estáveis (4101–4106) derivados do [config.id].
int mealReminderNotificationId(MealReminderConfig config) {
  switch (config.id) {
    case MealReminderDefaults.breakfastId:
      return 4101;
    case MealReminderDefaults.lunchId:
      return 4102;
    case MealReminderDefaults.dinnerId:
      return 4103;
    default:
      // Custom: faixa 4104–4199 a partir do hash do id.
      final hash = config.id.hashCode.abs() % 96;
      return 4104 + hash;
  }
}

/// Todos os IDs possíveis usados pelo app (para cancelamento completo).
List<int> allMealReminderNotificationIds(List<MealReminderConfig> reminders) {
  final ids = <int>{4101, 4102, 4103};
  for (final reminder in reminders) {
    ids.add(mealReminderNotificationId(reminder));
  }
  return ids.toList(growable: false);
}
