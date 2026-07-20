import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/analytics/analytics_service.dart';
import '../../../core/config/api_config.dart';
import '../../../features/auth/service/auth_service.dart';
import '../models/food_analysis_result.dart';

class FoodAnalysisHighDemandException implements Exception {
  const FoodAnalysisHighDemandException(this.message);

  final String message;

  @override
  String toString() => 'Exception: $message';
}

class FoodAnalysisService {
  const FoodAnalysisService();

  static String get _baseUrl => ApiConfig.baseUrl;
  /// Alinhado ao timeout total do backend (fallback de até 3 modelos).
  static const Duration _analysisTimeout = Duration(minutes: 2, seconds: 10);
  static const String highDemandMessage =
      'Estamos enfrentando uma sobrecarga na IA. '
      'Tente novamente em alguns instantes.';

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

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      stopwatch.stop();

      if (response.statusCode == 200 || response.statusCode == 201) {
        AnalyticsService.instance.track(
          'ai_analyze_succeeded',
          properties: <String, dynamic>{
            'latency_ms': stopwatch.elapsedMilliseconds,
            'has_image': hasImage,
            'source': 'client',
          },
        );
        unawaited(AnalyticsService.instance.flush());
        return FoodAnalysisResult.fromJson(decoded);
      }

      final message = _extractMessage(decoded, 'Falha ao analisar alimento');
      AnalyticsService.instance.track(
        'ai_analyze_failed',
        properties: <String, dynamic>{
          'error_code': response.statusCode.toString(),
          'latency_ms': stopwatch.elapsedMilliseconds,
          'source': 'client',
        },
      );

      if (_isHighDemandError(statusCode: response.statusCode, message: message)) {
        throw const FoodAnalysisHighDemandException(highDemandMessage);
      }

      throw Exception(message);
    } on TimeoutException {
      AnalyticsService.instance.track(
        'ai_analyze_failed',
        properties: <String, dynamic>{
          'error_code': 'timeout',
          'latency_ms': stopwatch.elapsedMilliseconds,
          'source': 'client',
        },
      );
      throw const FoodAnalysisHighDemandException(highDemandMessage);
    } on FoodAnalysisHighDemandException {
      rethrow;
    } catch (error) {
      if (error is! Exception ||
          !error.toString().contains('Falha ao analisar')) {
        AnalyticsService.instance.track(
          'ai_analyze_failed',
          properties: <String, dynamic>{
            'error_code': 'network',
            'latency_ms': stopwatch.elapsedMilliseconds,
            'source': 'client',
          },
        );
      }
      rethrow;
    }
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

  bool _isHighDemandError({required int statusCode, required String message}) {
    if (statusCode == 429 || statusCode == 503) {
      return true;
    }

    final normalizedMessage = message.toLowerCase();
    return normalizedMessage.contains('high demand') ||
        normalizedMessage.contains('alta demanda') ||
        normalizedMessage.contains('sobrecarga') ||
        normalizedMessage.contains('too many requests') ||
        normalizedMessage.contains('rate limit') ||
        normalizedMessage.contains('service unavailable');
  }
}
