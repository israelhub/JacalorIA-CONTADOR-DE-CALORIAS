import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'in_app_message_models.dart';
import 'meal_reminder_models.dart';
import 'meal_reminder_prefs.dart';

/// Inbox local de mensagens in-app (lembretes + avisos cadastrados).
class InAppMessageStore extends ChangeNotifier {
  InAppMessageStore._();

  static final InAppMessageStore instance = InAppMessageStore._();

  static const _storageKey = 'in_app_messages_v1';
  static const _dismissedKeysStorageKey = 'in_app_messages_dismissed_v1';
  static const _maxMessages = 100;
  static const _maxDismissedKeys = 200;

  List<InAppMessage> _messages = const <InAppMessage>[];
  Set<String> _dismissedSourceKeys = <String>{};
  var _loaded = false;
  Future<void> _writeQueue = Future<void>.value();

  List<InAppMessage> get messages => _messages;

  int get unreadCount => _messages.where((item) => item.isUnread).length;

  bool get isLoaded => _loaded;

  Future<void> ensureLoaded({SharedPreferences? preferences}) async {
    if (_loaded) {
      return;
    }
    await load(preferences: preferences);
  }

  Future<void> load({SharedPreferences? preferences}) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      _messages = const <InAppMessage>[];
    } else {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! List) {
          _messages = const <InAppMessage>[];
        } else {
          final items = <InAppMessage>[];
          for (final entry in decoded) {
            if (entry is! Map) {
              continue;
            }
            final message = InAppMessage.fromJson(
              Map<String, dynamic>.from(entry),
            );
            if (message.id.isEmpty) {
              continue;
            }
            items.add(message);
          }
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _messages = List<InAppMessage>.unmodifiable(items);
        }
      } catch (_) {
        _messages = const <InAppMessage>[];
      }
    }

    _dismissedSourceKeys = _loadDismissedKeys(prefs);

    _loaded = true;
    notifyListeners();
  }

  /// Insere (ou ignora se [sourceKey] já existir / foi descartada).
  Future<InAppMessage?> addMessage({
    required String title,
    required String body,
    required String source,
    String? id,
    String? sourceKey,
    DateTime? createdAt,
    SharedPreferences? preferences,
  }) {
    return _enqueue(() async {
      await ensureLoaded(preferences: preferences);

      if (sourceKey != null && sourceKey.isNotEmpty) {
        if (_dismissedSourceKeys.contains(sourceKey) ||
            _messages.any((item) => item.sourceKey == sourceKey)) {
          return null;
        }
      }

      final message = InAppMessage(
        id: id ?? 'msg_${DateTime.now().microsecondsSinceEpoch}',
        title: title.trim().isEmpty ? 'Aviso' : title.trim(),
        body: body.trim(),
        createdAt: createdAt ?? DateTime.now(),
        source: source,
        sourceKey: sourceKey,
      );

      final next = <InAppMessage>[message, ..._messages];
      if (next.length > _maxMessages) {
        next.removeRange(_maxMessages, next.length);
      }
      await _persist(next, preferences: preferences);
      return message;
    });
  }

  Future<void> markRead(
    String id, {
    SharedPreferences? preferences,
  }) {
    return _enqueue(() async {
      await ensureLoaded(preferences: preferences);
      final index = _messages.indexWhere((item) => item.id == id);
      if (index < 0 || !_messages[index].isUnread) {
        return;
      }

      final next = _messages.toList(growable: true);
      next[index] = next[index].copyWith(readAt: DateTime.now());
      await _persist(next, preferences: preferences);
    });
  }

  Future<void> markAllRead({SharedPreferences? preferences}) {
    return _enqueue(() async {
      await ensureLoaded(preferences: preferences);
      if (_messages.every((item) => !item.isUnread)) {
        return;
      }

      final now = DateTime.now();
      final next = _messages
          .map(
            (item) => item.isUnread ? item.copyWith(readAt: now) : item,
          )
          .toList(growable: false);
      await _persist(next, preferences: preferences);
    });
  }

  Future<void> delete(
    String id, {
    SharedPreferences? preferences,
  }) {
    return _enqueue(() async {
      await ensureLoaded(preferences: preferences);
      final index = _messages.indexWhere((item) => item.id == id);
      if (index < 0) {
        return;
      }

      final removed = _messages[index];
      final sourceKey = removed.sourceKey?.trim();
      if (sourceKey != null && sourceKey.isNotEmpty) {
        _dismissedSourceKeys = <String>{..._dismissedSourceKeys, sourceKey};
        await _persistDismissedKeys(preferences: preferences);
      }

      final next =
          _messages.where((item) => item.id != id).toList(growable: false);
      await _persist(next, preferences: preferences);
    });
  }

  /// Garante mensagens dos lembretes já vencidos hoje (nativo sem callback).
  Future<void> syncDueMealReminders({
    DateTime? now,
    SharedPreferences? preferences,
  }) async {
    await ensureLoaded(preferences: preferences);
    final settings = await MealReminderPrefs.load(preferences: preferences);
    if (!settings.masterEnabled) {
      return;
    }

    final current = now ?? DateTime.now();
    final dayKey =
        '${current.year.toString().padLeft(4, '0')}-'
        '${current.month.toString().padLeft(2, '0')}-'
        '${current.day.toString().padLeft(2, '0')}';

    await _pruneStaleMealReminderDismissals(
      dayKey: dayKey,
      preferences: preferences,
    );

    for (final config in settings.reminders) {
      if (!config.enabled) {
        continue;
      }
      final dueToday = DateTime(
        current.year,
        current.month,
        current.day,
        config.hour,
        config.minute,
      );
      if (current.isBefore(dueToday)) {
        continue;
      }

      final copy = mealReminderCopy(config);
      await addMessage(
        title: copy.title,
        body: copy.body,
        source: InAppMessageSources.mealReminder,
        sourceKey: 'meal_reminder:${config.id}:$dayKey',
        createdAt: dueToday,
        preferences: preferences,
      );
    }
  }

  /// Chamado quando um lembrete dispara de fato (ex.: timer web / show).
  Future<void> addMealReminderMessage(
    MealReminderConfig config, {
    DateTime? now,
    SharedPreferences? preferences,
  }) async {
    final current = now ?? DateTime.now();
    final dayKey =
        '${current.year.toString().padLeft(4, '0')}-'
        '${current.month.toString().padLeft(2, '0')}-'
        '${current.day.toString().padLeft(2, '0')}';
    final copy = mealReminderCopy(config);
    await addMessage(
      title: copy.title,
      body: copy.body,
      source: InAppMessageSources.mealReminder,
      sourceKey: 'meal_reminder:${config.id}:$dayKey',
      createdAt: current,
      preferences: preferences,
    );
  }

  Future<void> _persist(
    List<InAppMessage> next, {
    SharedPreferences? preferences,
  }) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final sorted = next.toList(growable: true)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _messages = List<InAppMessage>.unmodifiable(sorted);
    await prefs.setString(
      _storageKey,
      jsonEncode(_messages.map((item) => item.toJson()).toList(growable: false)),
    );
    notifyListeners();
  }

  Future<void> _persistDismissedKeys({SharedPreferences? preferences}) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    var keys = _dismissedSourceKeys.toList(growable: true)..sort();
    if (keys.length > _maxDismissedKeys) {
      keys = keys.sublist(keys.length - _maxDismissedKeys);
      _dismissedSourceKeys = keys.toSet();
    }
    await prefs.setString(
      _dismissedKeysStorageKey,
      jsonEncode(keys),
    );
  }

  Set<String> _loadDismissedKeys(SharedPreferences prefs) {
    final raw = prefs.getString(_dismissedKeysStorageKey);
    if (raw == null || raw.trim().isEmpty) {
      return <String>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <String>{};
      }
      final keys = <String>{};
      for (final entry in decoded) {
        final value = entry?.toString().trim() ?? '';
        if (value.isNotEmpty) {
          keys.add(value);
        }
      }
      return keys;
    } catch (_) {
      return <String>{};
    }
  }

  /// Remove dismissals de lembretes de dias anteriores (evita crescimento infinito).
  Future<void> _pruneStaleMealReminderDismissals({
    required String dayKey,
    SharedPreferences? preferences,
  }) {
    return _enqueue(() async {
      await ensureLoaded(preferences: preferences);
      final prefix = 'meal_reminder:';
      final kept = <String>{};
      var changed = false;
      for (final key in _dismissedSourceKeys) {
        if (key.startsWith(prefix) && !key.endsWith(':$dayKey')) {
          changed = true;
          continue;
        }
        kept.add(key);
      }
      if (!changed) {
        return;
      }
      _dismissedSourceKeys = kept;
      await _persistDismissedKeys(preferences: preferences);
    });
  }

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _writeQueue = _writeQueue.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  /// Apenas para testes.
  @visibleForTesting
  Future<void> resetForTest({SharedPreferences? preferences}) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_dismissedKeysStorageKey);
    _messages = const <InAppMessage>[];
    _dismissedSourceKeys = <String>{};
    _loaded = false;
    _writeQueue = Future<void>.value();
    notifyListeners();
  }

  /// Apenas para testes: simula restart mantendo SharedPreferences.
  @visibleForTesting
  Future<void> reloadFromDiskForTest({SharedPreferences? preferences}) async {
    await _writeQueue;
    _loaded = false;
    _messages = const <InAppMessage>[];
    _dismissedSourceKeys = <String>{};
    await load(preferences: preferences);
  }
}
