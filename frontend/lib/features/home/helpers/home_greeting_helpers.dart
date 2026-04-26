class HomeGreeting {
  const HomeGreeting({required this.label, required this.emoji});

  final String label;
  final String emoji;
}

HomeGreeting homeGreetingFor(DateTime now) {
  final hour = now.hour;

  if (hour >= 5 && hour < 12) {
    return const HomeGreeting(label: 'Bom dia,', emoji: '☀️');
  }

  if (hour >= 12 && hour < 18) {
    return const HomeGreeting(label: 'Boa tarde,', emoji: '🌤️');
  }

  return const HomeGreeting(label: 'Boa noite,', emoji: '🌙');
}

int readHomeProfileInt(
  Map<String, dynamic>? profile,
  List<String> keys, {
  int fallback = 0,
}) {
  if (profile == null) {
    return fallback;
  }

  for (final key in keys) {
    final value = profile[key];
    if (value is num) {
      return value.round();
    }

    if (value is String) {
      final parsed = num.tryParse(value);
      if (parsed != null) {
        return parsed.round();
      }
    }
  }

  return fallback;
}
