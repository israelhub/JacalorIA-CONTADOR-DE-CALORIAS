import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jacaloria/features/food_analysis/models/food_analysis_result.dart';
import 'package:jacaloria/features/food_analysis/pages/food_capture_page.dart';
import 'package:jacaloria/features/food_analysis/services/food_analysis_service.dart';

class _FakeFoodImagePicker implements FoodImagePicker {
  const _FakeFoodImagePicker(this._file);

  final XFile? _file;

  @override
  Future<XFile?> pickImage(ImageSource source) async => _file;
}

class _EmptyAnalysisService extends FoodAnalysisService {
  const _EmptyAnalysisService();

  @override
  Future<FoodAnalysisResult> analyzeImage({
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    return _emptyAnalysis;
  }

  @override
  Future<FoodAnalysisResult> recalculate({
    required List<FoodAnalysisItem> items,
  }) async {
    return _emptyAnalysis;
  }

  @override
  Future<FoodAnalysisResult> analyzeManualText(String manualText) async {
    return _emptyAnalysis;
  }
}

const _emptyAnalysis = FoodAnalysisResult(
  items: [],
  totals: FoodAnalysisTotals(calories: 0, protein: 0, carbs: 0, fat: 0),
  justification: 'Nenhum alimento detectado.',
);

final Uint8List _validPngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO5n8NQAAAAASUVORK5CYII=',
);

class _TestHomeHost extends StatelessWidget {
  const _TestHomeHost({
    required this.analysisService,
    required this.imagePicker,
  });

  final FoodAnalysisService analysisService;
  final FoodImagePicker imagePicker;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => FoodCapturePage(
                  analysisService: analysisService,
                  imagePicker: imagePicker,
                ),
              ),
            );
          },
          child: const Text('Abrir nova refeição'),
        ),
      ),
    );
  }
}

Future<void> _openCapturePage(WidgetTester tester) async {
  await tester.tap(find.text('Abrir nova refeição'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  expect(find.byType(FoodCapturePage), findsOneWidget);
}

void main() {
  group('FoodCapturePage', () {
    testWidgets(
      'mostra aviso com acoes quando imagem nao tem alimentos',
      (tester) async {
        tester.view.physicalSize = const Size(412, 917);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final file = XFile.fromData(
          _validPngBytes,
          name: 'meal.webp',
          mimeType: 'image/webp',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: _TestHomeHost(
              analysisService: const _EmptyAnalysisService(),
              imagePicker: _FakeFoodImagePicker(file),
            ),
          ),
        );

        await _openCapturePage(tester);

        await tester.tap(find.text('Galeria'));
          await tester.pump();
        await tester.pump(const Duration(milliseconds: 1200));

        expect(
          find.text('Não identificamos alimentos na análise.'),
          findsOneWidget,
        );
        expect(find.text('Voltar para home'), findsOneWidget);
        expect(find.text('Tentar novamente'), findsOneWidget);
      },
    );

    testWidgets(
      'mostra aviso com acoes quando digitacao nao tem alimentos',
      (tester) async {
        tester.view.physicalSize = const Size(412, 917);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final file = XFile.fromData(
          _validPngBytes,
          name: 'meal.webp',
          mimeType: 'image/webp',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: _TestHomeHost(
              analysisService: const _EmptyAnalysisService(),
              imagePicker: _FakeFoodImagePicker(file),
            ),
          ),
        );

        await _openCapturePage(tester);

        await tester.tap(find.text('Digitar'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await tester.enterText(
          find.byKey(const ValueKey('manual-food-entry-field')),
          'texto sem alimento reconhecivel',
        );

        await tester.tap(find.text('Continuar'));
          await tester.pump();
        await tester.pump(const Duration(milliseconds: 1200));

        expect(
          find.text('Não identificamos alimentos na análise.'),
          findsOneWidget,
        );
        expect(find.text('Voltar para home'), findsOneWidget);
        expect(find.text('Tentar novamente'), findsOneWidget);
      },
    );
  });
}
