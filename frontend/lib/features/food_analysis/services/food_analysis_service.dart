import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/analytics/analytics_service.dart';
import '../../../core/config/api_config.dart';
import '../../../features/auth/service/auth_service.dart';
import '../models/food_analysis_result.dart';

/// Erro de análise com mensagem pronta para exibir ao usuário.
class FoodAnalysisException implements Exception {
  const FoodAnalysisException(
    this.message, {
    this.canRetry = true,
    this.isHighDemand = false,
  });

  final String message;
  final bool canRetry;
  final bool isHighDemand;

  @override
  String toString() => 'Exception: $message';
}

/// Mantido por compatibilidade com telas/testes existentes.
class FoodAnalysisHighDemandException extends FoodAnalysisException {
  const FoodAnalysisHighDemandException([String? message])
      : super(
          message ?? FoodAnalysisService.highDemandMessage,
          canRetry: true,
          isHighDemand: true,
        );
}

class FoodAnalysisService {
  const FoodAnalysisService();

  static String get _baseUrl => ApiConfig.baseUrl;

  /// Abaixo do budget Nest (~55s) e do CloudFront (120s).
  static const Duration _analysisTimeout = Duration(seconds: 70);

  /// Uma re-tentativa automática para falhas transitórias (abort / HTML 504).
  static const int _maxAttempts = 2;

  static const String highDemandMessage =
      'Estamos enfrentando uma sobrecarga na IA. '
      'Tente novamente em alguns instantes.';

  static const String connectionErrorMessage =
      'Não foi possível conectar ao servidor. '
      'Verifique sua internet e tente novamente.';

  static const String timeoutMessage =
      'A análise demorou mais do que o esperado. '
      'Tente novamente em alguns instantes.';

  static const String serverErrorMessage =
      'Não conseguimos analisar a refeição agora. '
      'Tente novamente em alguns instantes.';

  static const String unexpectedErrorMessage =
      'Algo deu errado ao analisar a refeição. '
      'Tente novamente.';

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    final token = AuthService.globalToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<FoodAnalysisResult> analyzeImage({
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    return _postAnalysis(
      <String, dynamic>{
        'imageBase64': base64Encode(imageBytes),
        'mimeType': mimeType,
      },
      hasImage: true,
    );
  }

  Future<FoodAnalysisResult> recalculate({
    required List<FoodAnalysisItem> items,
  }) async {
    return _postAnalysis(
      <String, dynamic>{
        'items':
            items.map((item) => item.toReanalysisJson()).toList(growable: false),
      },
      hasImage: false,
      itemCount: items.length,
    );
  }

  Future<FoodAnalysisResult> analyzeManualText(String manualText) async {
    return _postAnalysis(
      <String, dynamic>{
        'manualText': manualText,
      },
      hasImage: false,
    );
  }

  /// Converte qualquer erro técnico em mensagem amigável.
  static FoodAnalysisException toUserFacingError(Object error) {
    if (error is FoodAnalysisException) {
      return error;
    }

    final raw = error.toString();
    final normalized = raw.toLowerCase();

    if (_looksLikeHighDemand(normalized)) {
      return const FoodAnalysisHighDemandException();
    }

    if (_looksLikeTimeout(normalized)) {
      return const FoodAnalysisException(
        timeoutMessage,
        isHighDemand: true,
      );
    }

    if (_looksLikeConnection(normalized) || error is http.ClientException) {
      return const FoodAnalysisException(connectionErrorMessage);
    }

    if (_looksLikeParseOrHtml(normalized) || error is FormatException) {
      return const FoodAnalysisException(serverErrorMessage);
    }

    // Evita vazar stack / URI / nomes de exception na UI.
    if (_looksTechnical(normalized)) {
      return const FoodAnalysisException(unexpectedErrorMessage);
    }

    final cleaned = raw.replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
    if (cleaned.isEmpty || _looksTechnical(cleaned.toLowerCase())) {
      return const FoodAnalysisException(unexpectedErrorMessage);
    }

    return FoodAnalysisException(cleaned);
  }

  Future<FoodAnalysisResult> _postAnalysis(
    Map<String, dynamic> body, {
    required bool hasImage,
    int? itemCount,
  }) async {
    final stopwatch = Stopwatch()..start();
    AnalyticsService.instance.track(
      'ai_analyze_requested',
      properties: <String, dynamic>{
        'has_image': hasImage,
        if (itemCount != null) 'item_count': itemCount,
        'source': 'client',
      },
    );

    Object? lastError;
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        return await _postAnalysisOnce(
          body,
          hasImage: hasImage,
          stopwatch: stopwatch,
          attempt: attempt,
        );
      } catch (error) {
        lastError = error;
        final mapped = toUserFacingError(error);
        final canAutoRetry =
            attempt < _maxAttempts && shouldAutoRetry(mapped, error);
        if (!canAutoRetry) {
          throw mapped;
        }
        AnalyticsService.instance.track(
          'ai_analyze_retry',
          properties: <String, dynamic>{
            'attempt': attempt,
            'latency_ms': stopwatch.elapsedMilliseconds,
            'source': 'client',
          },
        );
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
    }

    throw toUserFacingError(lastError ?? unexpectedErrorMessage);
  }

  Future<FoodAnalysisResult> _postAnalysisOnce(
    Map<String, dynamic> body, {
    required bool hasImage,
    required Stopwatch stopwatch,
    required int attempt,
  }) async {
    final uri = Uri.parse('$_baseUrl/ai/food/analyze');
    try {
      final response = await http
          .post(
            uri,
            headers: _headers(),
            body: jsonEncode(body),
          )
          .timeout(
            _analysisTimeout,
            onTimeout: () =>
                throw TimeoutException('Timeout na análise de alimento'),
          );

      final rawBody = response.body;
      if (_looksLikeHtmlBody(rawBody)) {
        AnalyticsService.instance.track(
          'ai_analyze_failed',
          properties: <String, dynamic>{
            'error_code': 'html_response_${response.statusCode}',
            'latency_ms': stopwatch.elapsedMilliseconds,
            'attempt': attempt,
            'source': 'client',
          },
        );
        // HTML quase sempre = 504/502 do proxy — transitório e retryável.
        throw const FoodAnalysisException(serverErrorMessage);
      }

      Map<String, dynamic> decoded;
      try {
        final parsed = jsonDecode(rawBody);
        if (parsed is! Map<String, dynamic>) {
          throw const FormatException('Resposta JSON inválida');
        }
        decoded = parsed;
      } on FormatException {
        AnalyticsService.instance.track(
          'ai_analyze_failed',
          properties: <String, dynamic>{
            'error_code': 'json_parse',
            'latency_ms': stopwatch.elapsedMilliseconds,
            'attempt': attempt,
            'source': 'client',
          },
        );
        throw const FoodAnalysisException(serverErrorMessage);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final meta = decoded['meta'];
        final model = meta is Map<String, dynamic>
            ? (meta['model'] as String?)?.trim()
            : null;
        final cacheHit = meta is Map<String, dynamic>
            ? meta['cacheHit'] == true
            : false;
        AnalyticsService.instance.track(
          'ai_analyze_succeeded',
          properties: <String, dynamic>{
            'latency_ms': stopwatch.elapsedMilliseconds,
            'has_image': hasImage,
            'attempt': attempt,
            'source': 'client',
            'model': (model != null && model.isNotEmpty)
                ? model
                : (cacheHit ? 'cache' : 'unknown'),
            if (meta is Map<String, dynamic>) ...<String, dynamic>{
              'cache_hit': cacheHit,
              if (meta['promptTokens'] != null)
                'prompt_tokens': meta['promptTokens'],
              if (meta['outputTokens'] != null)
                'output_tokens': meta['outputTokens'],
              if (meta['totalTokens'] != null)
                'total_tokens': meta['totalTokens'],
            },
          },
        );
        unawaited(AnalyticsService.instance.flush());
        return FoodAnalysisResult.fromJson(decoded);
      }

      final message = _extractMessage(decoded, serverErrorMessage);
      AnalyticsService.instance.track(
        'ai_analyze_failed',
        properties: <String, dynamic>{
          'error_code': response.statusCode.toString(),
          'latency_ms': stopwatch.elapsedMilliseconds,
          'attempt': attempt,
          'source': 'client',
        },
      );

      if (_isHighDemandError(statusCode: response.statusCode, message: message)) {
        throw const FoodAnalysisHighDemandException();
      }

      throw FoodAnalysisException(
        _sanitizeApiMessage(message),
        canRetry: response.statusCode >= 500 || response.statusCode == 408,
      );
    } on TimeoutException {
      AnalyticsService.instance.track(
        'ai_analyze_failed',
        properties: <String, dynamic>{
          'error_code': 'timeout',
          'latency_ms': stopwatch.elapsedMilliseconds,
          'attempt': attempt,
          'source': 'client',
        },
      );
      throw const FoodAnalysisHighDemandException(timeoutMessage);
    } on FoodAnalysisException {
      rethrow;
    } catch (error) {
      AnalyticsService.instance.track(
        'ai_analyze_failed',
        properties: <String, dynamic>{
          'error_code': 'network',
          'latency_ms': stopwatch.elapsedMilliseconds,
          'attempt': attempt,
          'source': 'client',
        },
      );
      throw toUserFacingError(error);
    }
  }

  /// Falhas tipicas de proxy/rede que costumam passar na 2a tentativa
  /// (cache/dedupe no backend ajuda se a 1a chegou a concluir no Nest).
  /// 503/cota da IA nao entra: retry imediato queima o restante dos modelos.
  static bool shouldAutoRetry(FoodAnalysisException mapped, Object error) {
    if (mapped.message == highDemandMessage) {
      return false;
    }
    if (mapped.message == connectionErrorMessage ||
        mapped.message == serverErrorMessage ||
        mapped.message == timeoutMessage ||
        mapped.isHighDemand) {
      return true;
    }
    final normalized = error.toString().toLowerCase();
    return _looksLikeConnection(normalized) ||
        _looksLikeParseOrHtml(normalized) ||
        _looksLikeHtmlBody(error.toString());
  }

  String _extractMessage(Map<String, dynamic> body, String fallback) {
    final message = body['message'];
    if (message is List && message.isNotEmpty) {
      return message.first.toString();
    }

    if (message is String && message.isNotEmpty) {
      return message;
    }

    return fallback;
  }

  String _sanitizeApiMessage(String message) {
    final normalized = message.toLowerCase();
    if (_looksTechnical(normalized) || _looksLikeParseOrHtml(normalized)) {
      return unexpectedErrorMessage;
    }
    return message;
  }

  bool _isHighDemandError({required int statusCode, required String message}) {
    if (statusCode == 429 || statusCode == 503) {
      return true;
    }
    return _looksLikeHighDemand(message.toLowerCase());
  }

  static bool _looksLikeHtmlBody(String body) {
    final trimmed = body.trimLeft();
    return trimmed.startsWith('<!') ||
        trimmed.startsWith('<html') ||
        trimmed.startsWith('<HTML') ||
        trimmed.startsWith('<?xml');
  }

  static bool _looksLikeHighDemand(String normalized) {
    return normalized.contains('high demand') ||
        normalized.contains('alta demanda') ||
        normalized.contains('sobrecarga') ||
        normalized.contains('too many requests') ||
        normalized.contains('rate limit') ||
        normalized.contains('service unavailable');
  }

  static bool _looksLikeTimeout(String normalized) {
    return normalized.contains('timeout') ||
        normalized.contains('timed out') ||
        normalized.contains('tempo esgotado');
  }

  static bool _looksLikeConnection(String normalized) {
    return normalized.contains('connection abort') ||
        normalized.contains('connection reset') ||
        normalized.contains('connection closed') ||
        normalized.contains('connection refused') ||
        normalized.contains('failed host lookup') ||
        normalized.contains('network is unreachable') ||
        normalized.contains('socketexception') ||
        normalized.contains('clientexception') ||
        normalized.contains('clientsoftware') ||
        normalized.contains('software caused connection') ||
        normalized.contains('broken pipe') ||
        normalized.contains('network error');
  }

  static bool _looksLikeParseOrHtml(String normalized) {
    return normalized.contains('formatexception') ||
        normalized.contains('formatsyntaxerror') ||
        normalized.contains('json parse') ||
        normalized.contains('unexpected token') ||
        normalized.contains('unrecognized token') ||
        normalized.contains('syntaxerror');
  }

  static bool _looksTechnical(String normalized) {
    return normalized.contains('uri=') ||
        normalized.contains('http://') ||
        normalized.contains('https://') ||
        normalized.contains('exception:') ||
        normalized.contains('error:') ||
        normalized.contains('statuscode') ||
        normalized.contains('stack trace') ||
        RegExp(r'\b[a-z]+exception\b').hasMatch(normalized) ||
        RegExp(r'\b[a-z]+error\b').hasMatch(normalized);
  }
}
