import 'dart:async';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'meal_reminder_models.dart';
import 'meal_reminder_prefs.dart';
import 'meal_reminder_home_widget.dart';
import 'in_app_message_store.dart';
import 'notifications_remote_service.dart';

/// Agenda lembretes locais diários (até [MealReminderSettings.maxReminders]).
///
/// - **Android/iOS**: `zonedSchedule` com repetição diária.
/// - **Web**: timers na aba aberta + `show()` (navegadores não suportam
///   agendamento nativo). A permissão só é pedida com gesto do usuário.
class MealReminderService {
  MealReminderService._();

  static final MealReminderService instance = MealReminderService._();

  static const _channelId = 'meal_reminders';
  static const _channelName = 'Lembretes de refeição';
  static const _channelDescription =
      'Avisos para registrar refeições no JacalorIA.';

  /// Silhueta monocromática do mascote (só o nome do drawable — sem @drawable/).
  /// O plugin valida com Resources.getIdentifier(..., "drawable", ...).
  static const _androidSmallIcon = 'ic_notification';

  /// Verde da marca (AppTheme.action500) aplicado ao small icon.
  static const _androidAccentColor = Color(0xFF7CBF4D);

  /// Logo colorido no corpo da notificação (também precisa ser drawable).
  static const _androidLargeIcon =
      DrawableResourceAndroidBitmap('ic_notification_large');

  /// Ícone do app nas notificações web (resolvido contra a base do site).
  static final Uri _webIconUrl = Uri.parse('icons/Icon-192.webp');

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final NotificationsRemoteService _remote = const NotificationsRemoteService();

  bool _initialized = false;
  bool _timezoneReady = false;

  /// IDs da última sincronização — para cancelar os que foram removidos.
  final Set<int> _lastScheduledIds = <int>{};

  /// Timers da web (navegador não agenda notificação no SO).
  final Map<int, Timer> _webTimers = <int, Timer>{};

  bool get isSupported {
    if (kIsWeb) {
      return true;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Na web os lembretes só disparam com a aba aberta.
  bool get usesInTabScheduling => kIsWeb;

  Future<void> initialize() async {
    if (!isSupported || _initialized) {
      return;
    }

    await _ensureTimezone();

    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const web = WebInitializationSettings();

    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(_androidSmallIcon),
          iOS: ios,
          web: web,
        ),
      );
    } catch (_) {
      // Fallback: build antigo sem ic_notification — ainda agenda lembretes.
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: ios,
          web: web,
        ),
      );
    }
    _initialized = true;
  }

  Future<void> applySettings(
    MealReminderSettings settings, {
    bool requestPermission = true,
  }) async {
    // Sempre persiste localmente primeiro — falha de ícone/agendamento
    // não pode impedir o usuário de salvar o horário.
    await MealReminderPrefs.save(settings);
    await MealReminderPrefs.setDirty(true);
    await _syncScheduledReminders(
      requestPermission: requestPermission,
      swallowErrors: true,
      pullRemote: false,
    );
    unawaited(_pushSettingsToRemote());
    unawaited(MealReminderHomeWidget.sync(settings: settings));
  }

  /// Garante que os lembretes ativos estejam agendados (boot / login / resume),
  /// sincronizando antes com o backend para refletir edições de outros
  /// dispositivos.
  Future<void> syncScheduledReminders({bool requestPermission = false}) async {
    await _syncScheduledReminders(
      requestPermission: requestPermission,
      swallowErrors: true,
      pullRemote: true,
    );
  }

  /// Envia as configurações locais ao backend; em sucesso, limpa o flag de
  /// pendência e guarda o `updatedAt` do servidor.
  Future<void> _pushSettingsToRemote() async {
    try {
      final settings = await MealReminderPrefs.load();
      final updatedAt = await _remote.saveReminderSettings(settings);
      if (updatedAt != null) {
        await MealReminderPrefs.saveRemoteUpdatedAt(updatedAt);
        await MealReminderPrefs.setDirty(false);
      }
    } catch (_) {
      // Sem rede/sessão: mantém dirty e tenta na próxima sincronização.
    }
  }

  /// Puxa do backend e adota se houver versão mais nova que a conhecida.
  /// Se houver edição local pendente, envia em vez de puxar (last-write-wins).
  Future<void> _pullSettingsFromRemote() async {
    try {
      if (await MealReminderPrefs.isDirty()) {
        await _pushSettingsToRemote();
        return;
      }

      final remote = await _remote.fetchReminderSettings();
      if (remote == null) {
        // Usuário nunca salvou no backend: publica o estado local para que
        // outros dispositivos herdem esses horários.
        await _pushSettingsToRemote();
        return;
      }

      final knownUpdatedAt = await MealReminderPrefs.loadRemoteUpdatedAt();
      if (knownUpdatedAt != remote.updatedAt) {
        await MealReminderPrefs.save(remote.settings);
        await MealReminderPrefs.saveRemoteUpdatedAt(remote.updatedAt);
        await MealReminderPrefs.setDirty(false);
      }
    } catch (_) {
      // Best-effort: sem rede continua com o estado local.
    }
  }

  Future<void> _syncScheduledReminders({
    required bool requestPermission,
    required bool swallowErrors,
    required bool pullRemote,
  }) async {
    if (!isSupported) {
      return;
    }

    try {
      await initialize();
      if (pullRemote) {
        await _pullSettingsFromRemote();
      }
      final settings = await MealReminderPrefs.load();

      if (!settings.masterEnabled) {
        await _cancelKnownReminders(settings.reminders);
        return;
      }

      final granted = await _ensurePermission(
        requestIfNeeded: requestPermission,
      );
      if (!granted) {
        await _cancelKnownReminders(settings.reminders);
        return;
      }

      final activeIds = <int>{};
      for (final config in settings.reminders) {
        final notificationId = mealReminderNotificationId(config);
        if (config.enabled) {
          if (kIsWeb) {
            _scheduleWebTimer(config);
          } else {
            await _scheduleDailyNative(config);
          }
          activeIds.add(notificationId);
        } else {
          await _cancelOne(notificationId);
        }
      }

      for (final staleId in _lastScheduledIds.difference(activeIds)) {
        await _cancelOne(staleId);
      }
      _lastScheduledIds
        ..clear()
        ..addAll(activeIds);
    } catch (_) {
      if (!swallowErrors) {
        rethrow;
      }
      // Boot/login: nunca derruba o app por falha de notificação.
    }
  }

  Future<bool> areNotificationsEnabled() async {
    if (!isSupported) {
      return false;
    }
    try {
      await initialize();
    } catch (_) {
      return false;
    }

    if (kIsWeb) {
      final web = _plugin.resolvePlatformSpecificImplementation<
          WebFlutterLocalNotificationsPlugin>();
      return web?.permissionStatus == WebNotificationPermission.granted;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.areNotificationsEnabled() ?? false;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final options = await ios?.checkPermissions();
      return options?.isEnabled ?? false;
    }

    return false;
  }

  Future<bool> requestPermission() async {
    if (!isSupported) {
      return false;
    }
    await initialize();
    await MealReminderPrefs.markPermissionPrompted();
    return _requestPlatformPermission();
  }

  Future<void> _ensureTimezone() async {
    if (_timezoneReady) {
      return;
    }
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    _timezoneReady = true;
  }

  Future<bool> _ensurePermission({required bool requestIfNeeded}) async {
    final alreadyEnabled = await areNotificationsEnabled();
    if (alreadyEnabled) {
      return true;
    }

    // Na web o browser exige gesto do usuário; nunca pedir no boot/login.
    if (kIsWeb) {
      if (!requestIfNeeded) {
        return false;
      }
      return requestPermission();
    }

    final prompted = await MealReminderPrefs.wasPermissionPrompted();
    if (!requestIfNeeded && prompted) {
      return false;
    }

    if (!requestIfNeeded && !prompted) {
      return requestPermission();
    }

    if (requestIfNeeded) {
      return requestPermission();
    }

    return false;
  }

  Future<bool> _requestPlatformPermission() async {
    if (kIsWeb) {
      final web = _plugin.resolvePlatformSpecificImplementation<
          WebFlutterLocalNotificationsPlugin>();
      if (web == null) {
        return false;
      }
      if (web.permissionStatus == WebNotificationPermission.denied) {
        return false;
      }
      if (web.permissionStatus == WebNotificationPermission.granted) {
        return true;
      }
      final granted = await web.requestNotificationsPermission();
      return granted ?? false;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  Future<void> _cancelKnownReminders(List<MealReminderConfig> reminders) async {
    final ids = <int>{
      ...allMealReminderNotificationIds(reminders),
      ..._lastScheduledIds,
      ..._webTimers.keys,
    };
    for (final id in ids) {
      await _cancelOne(id);
    }
    _lastScheduledIds.clear();
  }

  Future<void> _cancelOne(int notificationId) async {
    _webTimers.remove(notificationId)?.cancel();
    if (!kIsWeb) {
      await _plugin.cancel(id: notificationId);
    }
  }

  void _scheduleWebTimer(MealReminderConfig config) {
    final notificationId = mealReminderNotificationId(config);
    _webTimers.remove(notificationId)?.cancel();

    final when = nextInstanceOfTime(hour: config.hour, minute: config.minute);
    final now = tz.TZDateTime.now(tz.local);
    var delay = when.difference(now);
    if (delay.isNegative || delay.inMilliseconds == 0) {
      delay = const Duration(days: 1);
    }

    _webTimers[notificationId] = Timer(delay, () {
      unawaited(_onWebTimerFired(config));
    });
  }

  Future<void> _onWebTimerFired(MealReminderConfig config) async {
    try {
      final settings = await MealReminderPrefs.load();
      if (!settings.masterEnabled) {
        return;
      }
      final current = settings.byId(config.id);
      if (current == null || !current.enabled) {
        return;
      }
      if (!await areNotificationsEnabled()) {
        return;
      }
      await _showNow(current);
      // Reagenda o próximo dia enquanto a aba continuar aberta.
      _scheduleWebTimer(current);
      _lastScheduledIds.add(mealReminderNotificationId(current));
    } catch (_) {}
  }

  Future<void> _showNow(MealReminderConfig config) async {
    final copy = mealReminderCopy(config);
    await _plugin.show(
      id: mealReminderNotificationId(config),
      title: copy.title,
      body: copy.body,
      payload: 'meal_reminder:${config.id}',
      notificationDetails: NotificationDetails(
        android: const AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          icon: _androidSmallIcon,
          color: _androidAccentColor,
          largeIcon: _androidLargeIcon,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        web: WebNotificationDetails(
          requireInteraction: false,
          lang: 'pt-BR',
          iconUrl: _webIconUrl,
        ),
      ),
    );
    unawaited(InAppMessageStore.instance.addMealReminderMessage(config));
    unawaited(MealReminderHomeWidget.sync());
  }

  Future<void> _scheduleDailyNative(MealReminderConfig config) async {
    final copy = mealReminderCopy(config);
    final when = nextInstanceOfTime(
      hour: config.hour,
      minute: config.minute,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    Future<void> schedule(AndroidNotificationDetails androidDetails) {
      return _plugin.zonedSchedule(
        id: mealReminderNotificationId(config),
        scheduledDate: when,
        notificationDetails: NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: copy.title,
        body: copy.body,
        payload: 'meal_reminder:${config.id}',
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    try {
      await schedule(
        const AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          icon: _androidSmallIcon,
          color: _androidAccentColor,
          largeIcon: _androidLargeIcon,
        ),
      );
    } catch (_) {
      // Sem drawables novos: agenda com o ícone padrão do init.
      await schedule(
        const AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
        ),
      );
    }
  }
}

/// Próxima ocorrência local de [hour]:[minute] (amanhã se já passou hoje).
tz.TZDateTime nextInstanceOfTime({
  required int hour,
  required int minute,
  tz.Location? location,
  DateTime? now,
}) {
  final loc = location ?? tz.local;
  final current = now != null
      ? tz.TZDateTime.from(now, loc)
      : tz.TZDateTime.now(loc);
  var scheduled = tz.TZDateTime(
    loc,
    current.year,
    current.month,
    current.day,
    hour,
    minute,
  );
  if (!scheduled.isAfter(current)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}
