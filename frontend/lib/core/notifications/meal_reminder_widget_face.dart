import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';
import 'meal_reminder_widget_snapshot.dart';

class MealReminderHomeWidgetFace extends StatelessWidget {
  const MealReminderHomeWidgetFace({
    super.key,
    required this.snapshot,
  });

  static const logicalSize = Size(340, 118);
  static const mascotAsset = 'assets/images/widget/widget_jaca_saindo.png';

  final MealReminderWidgetSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final unit = snapshot.streakDays == 1
        ? 'dia de sequência'
        : 'dias de sequência';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 26,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: <Color>[Color(0xFF1E513E), Color(0xFF3A7A4F)],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFF2F6A52)),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x33000000),
                  offset: Offset(0, 4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 118, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 28, height: 1)),
                      const SizedBox(width: 4),
                      Text(
                        '${snapshot.streakDays}',
                        style: const TextStyle(
                          color: Color(0xFFFFE0B8),
                          fontSize: 44,
                          height: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        unit,
                        style: const TextStyle(
                          color: Color(0xFFFFE0B8),
                          fontSize: 15,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    snapshot.messageTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    snapshot.messageBody,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.brand300,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 2,
          bottom: 0,
          child: Image.asset(
            mascotAsset,
            width: 124,
            height: 124,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ],
    );
  }
}
