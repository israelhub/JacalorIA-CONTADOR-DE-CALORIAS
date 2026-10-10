import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppAmbientPageGlow extends StatelessWidget {
  const AppAmbientPageGlow({super.key});

  static const Color _yellowPastel = Color(0xFFF5F1D0);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-1.0, -1.05),
                radius: 3.1,
                colors: [
                  AppColors.brand300.withValues(alpha: 1.0),
                  AppColors.brand300.withValues(alpha: 0.58),
                  AppColors.brand300.withValues(alpha: 0.3),
                  AppColors.brand300.withValues(alpha: 0.15),
                  AppColors.brand300.withValues(alpha: 0.07),
                  AppColors.brand300.withValues(alpha: 0.028),
                  AppColors.pageBackground.withValues(alpha: 0),
                ],
                stops: const [0.0, 0.12, 0.26, 0.44, 0.62, 0.82, 1.0],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(1.05, -0.08),
                      radius: 1.1,
                      colors: [
                        _yellowPastel.withValues(alpha: 0.92),
                        _yellowPastel.withValues(alpha: 0.78),
                        _yellowPastel.withValues(alpha: 0.4),
                        _yellowPastel.withValues(alpha: 0.18),
                        _yellowPastel.withValues(alpha: 0.06),
                        AppColors.pageBackground.withValues(alpha: 0),
                      ],
                      stops: const [0.0, 0.14, 0.32, 0.52, 0.74, 1.0],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppAmbientPageBody extends StatelessWidget {
  const AppAmbientPageBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: AppAmbientPageGlow()),
        child,
      ],
    );
  }
}
