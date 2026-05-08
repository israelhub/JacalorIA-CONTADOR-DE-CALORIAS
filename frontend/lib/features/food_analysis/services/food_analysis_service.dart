import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/food_analysis_result.dart';

import '../../../core/config/api_config.dart';

class FoodAnalysisHighDemandException implements Exception {
  const FoodAnalysisHighDemandException(this.message);

  final String message;

  @override
  String toString() => 'Exception: $message';
}

class FoodAnalysisService {
  const FoodAnalysisService();

  static String get _baseUrl => ApiConfig.baseUrl;
  static const String highDemandMessage =
      'Pedimos desculpas, nossa IA está enfrentando um período de alta '
      'demanda no momento. Tente novamente em alguns instantes.';

  Future<FoodAnalysisResult> analyzeImage({
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    return _postAnalysis(<String, dynamic>{
      'imageBase64': base64Encode(imageBytes),
      'mimeType': mimeType,
    });
  }

  Future<FoodAnalysisResult> recalculate({
    required List<FoodAnalysisItem> items,
  }) async {
    return _postAnalysis(<String, dynamic>{
      'items': items.map((item) => item.toReanalysisJson()).toList(growable: false),
    });
  }

  Future<FoodAnalysisResult> _postAnalysis(Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl/ai/food/analyze');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(
          const Duration(seconds: 25),
          onTimeout: () =>
              throw TimeoutException('Timeout na análise de alimento'),
        );

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 || response.statusCode == 201) {
      return FoodAnalysisResult.fromJson(decoded);
    }

    final message = _extractMessage(decoded, 'Falha ao analisar alimento');
    if (_isHighDemandError(statusCode: response.statusCode, message: message)) {
      throw const FoodAnalysisHighDemandException(highDemandMessage);
    }

    throw Exception(message);
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
    if (statusCode == 429) {
      return true;
    }

    final normalizedMessage = message.toLowerCase();
    return normalizedMessage.contains('high demand') ||
        normalizedMessage.contains('alta demanda') ||
        normalizedMessage.contains('too many requests') ||
        normalizedMessage.contains('rate limit');
  }
}
