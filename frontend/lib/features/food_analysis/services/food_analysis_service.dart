import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/food_analysis_result.dart';

class FoodAnalysisService {
  const FoodAnalysisService();

  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get _baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }

    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://127.0.0.1:3000/api'
        : 'http://localhost:3000/api';
  }

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

    throw Exception(_extractMessage(decoded, 'Falha ao analisar alimento'));
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
}
