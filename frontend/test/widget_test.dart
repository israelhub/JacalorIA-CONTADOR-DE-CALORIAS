// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jacaloria/main.dart' as app;

void main() {
  testWidgets('Bootstrap trava o app em retrato', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final calls = <MethodCall>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall methodCall,
        ) async {
          calls.add(methodCall);
          return null;
        });

    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await app.main();

    expect(
      calls,
      contains(
        isA<MethodCall>()
            .having(
              (MethodCall call) => call.method,
              'method',
              'SystemChrome.setPreferredOrientations',
            )
            .having((MethodCall call) => call.arguments, 'arguments', <String>[
              'DeviceOrientation.portraitUp',
            ]),
      ),
    );

  });

  testWidgets('App inicia na tela de entrada', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const app.MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Vamos começar'), findsOneWidget);
    expect(find.text('Criar conta'), findsOneWidget);
    expect(find.text('Já tenho uma conta'), findsOneWidget);
  });
}
