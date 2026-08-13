import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/food_analysis/models/food_analysis_result.dart';
import 'package:jacaloria/features/food_analysis/pages/food_analysis_processing_page.dart';
import 'package:jacaloria/features/food_analysis/services/food_analysis_service.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

/// 1x1 PNG transparente — suficiente para ativar o overlay de preview.
Uint8List _tinyPng() => Uint8List.fromList(const <int>[
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
      0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
      0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);

FoodAnalysisResult _sampleResult() {
  return const FoodAnalysisResult(
    items: [],
    totals: FoodAnalysisTotals(
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
    ),
    justification: '',
  );
}

void main() {
  testWidgets('mostra a tela intermediaria de analise', (tester) async {
    final completer = Completer<FoodAnalysisResult>();

    await tester.pumpWidget(
      _wrap(
        FoodAnalysisProcessingPage(
          imageBytes: _tinyPng(),
          title: 'Analisando...',
          message: 'A inteligência artificial está analisando a sua refeição...',
          operation: () => completer.future,
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Nova refeição'), findsOneWidget);
    expect(find.text('Analisando...'), findsOneWidget);
    expect(
      find.text('A inteligência artificial está analisando a sua refeição...'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
  });

  testWidgets('avanca mensagem de espera apos demora', (tester) async {
    final completer = Completer<FoodAnalysisResult>();

    await tester.pumpWidget(
      _wrap(
        FoodAnalysisProcessingPage(
          imageBytes: _tinyPng(),
          title: 'Analisando...',
          message: 'A inteligência artificial está analisando sua refeição...',
          operation: () => completer.future,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 13));

    expect(find.text('Ainda analisando...'), findsOneWidget);
    expect(
      find.textContaining('Estamos olhando bem o prato'),
      findsOneWidget,
    );
    expect(find.textContaining('nesta análise'), findsOneWidget);
  });

  testWidgets('mostra erro amigavel e para de analisar', (tester) async {
    await tester.pumpWidget(
      _wrap(
        FoodAnalysisProcessingPage(
          imageBytes: _tinyPng(),
          title: 'Analisando...',
          message: 'A inteligência artificial está analisando sua refeição...',
          operation: () async {
            throw Exception(
              'ClientSoftware caused connection abort, '
              'uri=https://jacaloria.online/api/ai/food/analyze',
            );
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível'), findsOneWidget);
    expect(find.text(FoodAnalysisService.connectionErrorMessage), findsOneWidget);
    expect(find.text('Analisando...'), findsNothing);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('mapeia JSON parse html para mensagem amigavel', (tester) async {
    await tester.pumpWidget(
      _wrap(
        FoodAnalysisProcessingPage(
          imageBytes: _tinyPng(),
          title: 'Analisando...',
          message: 'mensagem inicial',
          operation: () async {
            throw const FormatException(
              "JSON Parse error: Unrecognized token '<'",
            );
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text(FoodAnalysisService.serverErrorMessage), findsOneWidget);
    expect(find.textContaining('FormatException'), findsNothing);
    expect(find.textContaining('Unrecognized token'), findsNothing);
  });

  test('toUserFacingError cobre os erros das imagens', () {
    final connection = FoodAnalysisService.toUserFacingError(
      Exception(
        'ClientSoftware caused connection abort, '
        'uri=https://jacaloria.online/api/ai/food/analyze',
      ),
    );
    expect(connection.message, FoodAnalysisService.connectionErrorMessage);

    final parse = FoodAnalysisService.toUserFacingError(
      Exception("FormatSyntaxError: JSON Parse error: Unrecognized token '<'"),
    );
    expect(parse.message, FoodAnalysisService.serverErrorMessage);
  });

  test('nao faz auto-retry em sobrecarga 503 da IA', () {
    final overload = FoodAnalysisService.toUserFacingError(
      Exception('Estamos enfrentando uma sobrecarga na IA. Tente novamente'),
    );
    expect(
      FoodAnalysisService.shouldAutoRetry(overload, overload),
      isFalse,
    );
  });

  test('faz auto-retry em timeout e falha de conexao', () {
    const timeout = const FoodAnalysisHighDemandException(
      FoodAnalysisService.timeoutMessage,
    );
    expect(
      FoodAnalysisService.shouldAutoRetry(timeout, timeout),
      isTrue,
    );

    final connection = FoodAnalysisService.toUserFacingError(
      Exception('connection abort'),
    );
    expect(
      FoodAnalysisService.shouldAutoRetry(connection, connection),
      isTrue,
    );
  });

  testWidgets('permite retentar apos erro', (tester) async {
    var attempts = 0;
    final completer = Completer<FoodAnalysisResult>();

    await tester.pumpWidget(
      _wrap(
        FoodAnalysisProcessingPage(
          imageBytes: _tinyPng(),
          title: 'Analisando...',
          message: 'mensagem inicial',
          operation: () async {
            attempts += 1;
            if (attempts == 1) {
              throw Exception('connection abort');
            }
            return completer.future;
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Tentar novamente'), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();

    expect(attempts, 2);
    expect(find.text('Analisando...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(_sampleResult());
    await tester.pumpAndSettle();
  });
}
