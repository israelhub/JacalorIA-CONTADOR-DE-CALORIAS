import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';
import 'meal_reminder_widget_snapshot.dart';

class MealReminderWidgetConceptsSheet extends StatelessWidget {
  const MealReminderWidgetConceptsSheet({super.key, required this.snapshot});

  static const logicalSize = Size(380, 430);

  final MealReminderWidgetSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF141414),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Opções de widget',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFEDEDED),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            _LabeledConcept(
              label: 'A · Balão do Jaca',
              child: MealReminderConceptSpeech(snapshot: snapshot),
            ),
            const SizedBox(height: 14),
            _LabeledConcept(
              label: 'B · Foguinho gigante',
              child: MealReminderConceptStreakHero(snapshot: snapshot),
            ),
            const SizedBox(height: 14),
            _LabeledConcept(
              label: 'C · Ímã de geladeira',
              child: MealReminderConceptFridgeMagnet(snapshot: snapshot),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledConcept extends StatelessWidget {
  const _LabeledConcept({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB8B8B8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(width: 340, height: 96, child: child),
      ],
    );
  }
}

class MealReminderConceptSpeech extends StatelessWidget {
  const MealReminderConceptSpeech({super.key, required this.snapshot});

  final MealReminderWidgetSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          const ColoredBox(color: Color(0xFFFFF6E8), child: SizedBox.expand()),
          Positioned(
            left: -18,
            top: -22,
            child: Image.asset(
              'assets/images/jaca_emojis/fome.png',
              width: 128,
              height: 128,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: 10,
            right: 12,
            child: _FireChip(days: snapshot.streakDays),
          ),
          Positioned(
            left: 96,
            right: 12,
            top: 38,
            bottom: 10,
            child: CustomPaint(
              painter: const _BubblePainter(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      snapshot.messageTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.brand900Variant,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      snapshot.messageBody,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MealReminderConceptStreakHero extends StatelessWidget {
  const MealReminderConceptStreakHero({super.key, required this.snapshot});

  final MealReminderWidgetSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final unit = snapshot.streakDays == 1 ? 'dia' : 'dias';
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: <Color>[Color(0xFF1E513E), Color(0xFF3A7A4F)],
              ),
            ),
            child: SizedBox.expand(),
          ),
          Positioned(
            right: -28,
            bottom: -30,
            child: Image.asset(
              'assets/images/jaca_emojis/festa.png',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 110, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 28, height: 1)),
                    const SizedBox(width: 4),
                    Text(
                      '${snapshot.streakDays}',
                      style: const TextStyle(
                        color: Color(0xFFFFE0B8),
                        fontSize: 42,
                        height: 0.9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 6),
                      child: Text(
                        unit,
                        style: const TextStyle(
                          color: Color(0xFFFFE0B8),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  snapshot.messageBody,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.brand300,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MealReminderConceptFridgeMagnet extends StatelessWidget {
  const MealReminderConceptFridgeMagnet({super.key, required this.snapshot});

  final MealReminderWidgetSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: ColoredBox(
        color: const Color(0xFFE7F4DC),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x33000000),
                        offset: Offset(0, 3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/jaca_emojis/fome.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: -6,
                  top: -4,
                  child: _FireChip(days: snapshot.streakDays),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFCF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE8D9C4),
                    width: 1.4,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      snapshot.messageTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.brand900Variant,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      snapshot.messageBody,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FireChip extends StatelessWidget {
  const _FireChip({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF8A3C),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Text(
        '🔥 $days',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bubble = RRect.fromLTRBR(
      10,
      0,
      size.width,
      size.height,
      const Radius.circular(16),
    );
    final fill = Paint()..color = Colors.white;
    final stroke = Paint()
      ..color = const Color(0xFFE8D9C4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final tail = Path()
      ..moveTo(12, size.height * 0.38)
      ..lineTo(0, size.height * 0.48)
      ..lineTo(12, size.height * 0.62)
      ..close();

    canvas.drawPath(tail, fill);
    canvas.drawRRect(bubble, fill);
    canvas.drawPath(tail, stroke);
    canvas.drawRRect(bubble, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
