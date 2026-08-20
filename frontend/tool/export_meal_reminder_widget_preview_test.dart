import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/core/images/widget_image_exporter.dart';
import 'package:jacaloria/core/notifications/meal_reminder_models.dart';
import 'package:jacaloria/core/notifications/meal_reminder_widget_face.dart';
import 'package:jacaloria/core/notifications/meal_reminder_widget_snapshot.dart';

void main() {
  test('exporta preview do widget Android', () async {
    TestWidgetsFlutterBinding.ensureInitialized();

    final snapshot = buildMealReminderWidgetSnapshot(
      settings: MealReminderSettings.defaults(),
      streakDays: 3,
      now: DateTime(2026, 8, 19, 12, 10),
    );

    final previewBytes = await exportWidgetToImageBytes(
      widget: ColoredBox(
        color: const Color(0xFF1A1A1A),
        child: Center(
          child: SizedBox(
            width: MealReminderHomeWidgetFace.logicalSize.width,
            height: MealReminderHomeWidgetFace.logicalSize.height,
            child: MealReminderHomeWidgetFace(snapshot: snapshot),
          ),
        ),
      ),
      logicalSize: const Size(380, 160),
      pixelRatio: 3,
      asJpeg: false,
    );

    final file = File('android/widget_preview/meal_reminder_widget.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(previewBytes);
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(1000));
  });
}
