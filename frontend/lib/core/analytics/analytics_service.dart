import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/service/auth_service.dart';
import '../config/api_config.dart';

/// Client-side product analytics → `POST /api/analytics/events`.
///
/// Batches events and flushes periodically. Tracks session duration while
/// the app is in foreground. Never throws to callers.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  static const _sessionPrefsKey = 'analytics_session_id';
  static const _flushInterval = Duration(seconds: 8);
  static const _heartbeatInterval = Duration(seconds: 60);
  static const _sessionTimeout = Duration(minutes: 30);
  static const _maxBatch = 40;

  final List<Map<String, dynamic>> _queue = <Map<String, dynamic>>[];
  Timer? _flushTimer;
  Timer? _heartbeatTimer;
  String? _sessionId;
  bool _flushing = false;
  DateTime? _lastAppOpenAt;

  DateTime? _sessionStartedAt;
  DateTime? _foregroundSince;
  int _accumulatedForegroundMs = 0;
  bool _isInForeground = false;
  String? _currentScreen;

  String get platform {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return defaultTargetPlatform.name;
    }
  }

  String? get sessionId => _sessionId;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    var sessionId = prefs.getString(_sessionPrefsKey);
    if (sessionId == null || sessionId.isEmpty) {
      sessionId = _generateSessionId();
      await prefs.setString(_sessionPrefsKey, sessionId);
    }
    _sessionId = sessionId;
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(_flushInterval, (_) {
      unawaited(flush());
    });
  }

  /// Starts a new analytics session (e.g. after login).
  Future<void> startSession({String reason = 'auth'}) async {
    await _closeForegroundSession(reason: 'new_session');
    final prefs = await SharedPreferences.getInstance();
    _sessionId = _generateSessionId();
    await prefs.setString(_sessionPrefsKey, _sessionId!);
    _sessionStartedAt = DateTime.now();
    _accumulatedForegroundMs = 0;
    _foregroundSince = null;
    track('session_start', properties: {'reason': reason});
  }

  void track(
    String eventName, {
    Map<String, dynamic>? properties,
    DateTime? occurredAt,
  }) {
    if (eventName.trim().isEmpty) return;

    final props = <String, dynamic>{
      if (_currentScreen != null) 'screen': _currentScreen,
      ...?properties,
    };

    _queue.add(<String, dynamic>{
      'eventName': eventName,
      'occurredAt': (occurredAt ?? DateTime.now().toUtc()).toIso8601String(),
      'platform': platform,
      'sessionId': _sessionId,
      'properties': props,
    });

    if (_queue.length >= _maxBatch) {
      unawaited(flush());
    }
  }

  /// Screen / page view for funnel and engagement.
  void trackScreen(String screenName, {Map<String, dynamic>? properties}) {
    final name = screenName.trim();
    if (name.isEmpty) return;
    _currentScreen = name;
    track(
      'screen_view',
      properties: <String, dynamic>{
        'screen_name': name,
        ...?properties,
      },
    );
  }

  /// Deduped app_open (min 30s between sends) + foreground session.
  void trackAppOpen({Map<String, dynamic>? properties}) {
    final now = DateTime.now();
    if (_lastAppOpenAt != null &&
        now.difference(_lastAppOpenAt!) < const Duration(seconds: 30)) {
      unawaited(enterForeground(reason: 'app_open_deduped'));
      return;
    }
    _lastAppOpenAt = now;
    track('app_open', properties: properties);
    unawaited(enterForeground(reason: properties?['from']?.toString() ?? 'open'));
    unawaited(flush());
  }

  /// App entered foreground — starts/resumes session clock.
  Future<void> enterForeground({String reason = 'resume'}) async {
    final now = DateTime.now();

    final timedOut = _lastBackgroundAt != null &&
        now.difference(_lastBackgroundAt!) >= _sessionTimeout;

    if (_sessionStartedAt == null || timedOut) {
      if (_sessionStartedAt != null && timedOut) {
        // Close previous session without double-counting paused time.
        _isInForeground = false;
        _foregroundSince = null;
      }
      await startSession(reason: timedOut ? 'timeout' : reason);
    }

    if (_isInForeground) return;

    _isInForeground = true;
    _foregroundSince = now;
    _accumulatedForegroundMs = 0;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _emitHeartbeat();
    });
  }

  DateTime? _lastBackgroundAt;

  /// App left foreground — freezes clock and emits session_end snapshot.
  Future<void> leaveForeground({String reason = 'pause'}) async {
    _lastBackgroundAt = DateTime.now();
    await _closeForegroundSession(reason: reason, emitEnd: true);
  }

  Future<void> _closeForegroundSession({
    required String reason,
    bool emitEnd = false,
  }) async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    if (_isInForeground && _foregroundSince != null) {
      _accumulatedForegroundMs +=
          DateTime.now().difference(_foregroundSince!).inMilliseconds;
    }
    _isInForeground = false;
    _foregroundSince = null;

    if (emitEnd && _sessionStartedAt != null && _accumulatedForegroundMs > 0) {
      track(
        'session_end',
        properties: <String, dynamic>{
          'reason': reason,
          'duration_ms': _accumulatedForegroundMs,
          'duration_sec': (_accumulatedForegroundMs / 1000).round(),
        },
      );
      unawaited(flush());
    }
  }

  void _emitHeartbeat() {
    if (!_isInForeground || _sessionStartedAt == null) return;

    var elapsed = _accumulatedForegroundMs;
    if (_foregroundSince != null) {
      elapsed += DateTime.now().difference(_foregroundSince!).inMilliseconds;
    }

    track(
      'session_heartbeat',
      properties: <String, dynamic>{
        'duration_ms': elapsed,
        'duration_sec': (elapsed / 1000).round(),
        if (_currentScreen != null) 'screen_name': _currentScreen,
      },
    );
  }

  /// Current foreground duration in ms (including active segment).
  int get currentSessionDurationMs {
    var elapsed = _accumulatedForegroundMs;
    if (_isInForeground && _foregroundSince != null) {
      elapsed += DateTime.now().difference(_foregroundSince!).inMilliseconds;
    }
    return elapsed;
  }

  Future<void> flush() async {
    if (_flushing || _queue.isEmpty) return;

    final token = AuthService.globalToken;
    if (token == null || token.isEmpty) {
      _queue.clear();
      return;
    }

    _flushing = true;
    final batch = List<Map<String, dynamic>>.from(_queue);
    _queue.clear();

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/analytics/events');
      final response = await http
          .post(
            uri,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(<String, dynamic>{'events': batch}),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _queue.insertAll(0, batch);
        if (kDebugMode) {
          debugPrint(
            'Analytics flush failed: ${response.statusCode} ${response.body}',
          );
        }
      }
    } catch (error) {
      _queue.insertAll(0, batch);
      if (kDebugMode) {
        debugPrint('Analytics flush error: $error');
      }
    } finally {
      _flushing = false;
    }
  }

  String _generateSessionId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
