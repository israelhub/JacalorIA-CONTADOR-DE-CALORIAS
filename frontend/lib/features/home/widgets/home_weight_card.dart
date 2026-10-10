import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import 'home_steps_card.dart';
import 'home_weight_quick_edit_button.dart';

class HomeWeightCard extends StatefulWidget {
  const HomeWeightCard({
    super.key,
    required this.userProfile,
    required this.onWeightUpdated,
  });

  final Map<String, dynamic>? userProfile;
  final ValueChanged<Map<String, dynamic>> onWeightUpdated;

  static const double cardHeight = HomeStepsCard.cardHeight;
  static const _mascotAsset = 'assets/images/jaca_weight.jpg';

  @override
  State<HomeWeightCard> createState() => _HomeWeightCardState();
}

class _HomeWeightCardState extends State<HomeWeightCard> {
  final _weightController = HomeWeightQuickEditController();

  double get _currentWeight {
    final rawWeight = widget.userProfile?['weight'];
    if (rawWeight is num) {
      return rawWeight.toDouble();
    }
    if (rawWeight is String && rawWeight.trim().isNotEmpty) {
      return double.tryParse(rawWeight.replaceAll(',', '.')) ?? 0;
    }
    return 0;
  }

  String get _currentUnit {
    final unit =
        (widget.userProfile?['weightUnit'] as String?) ??
        (widget.userProfile?['weight_unit'] as String?);
    return unit?.trim().isNotEmpty == true ? unit!.trim() : 'kg';
  }

  String get _weightLabel {
    final value = _currentWeight;
    if (value <= 0) {
      return '--';
    }
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg);

    return Stack(
      children: [
        Positioned(
          width: 1,
          height: 1,
          right: 0,
          bottom: 0,
          child: HomeWeightQuickEditButton(
            userProfile: widget.userProfile,
            onWeightUpdated: widget.onWeightUpdated,
            controller: _weightController,
            showTrigger: false,
          ),
        ),
        Container(
          key: const ValueKey('home-weight-card'),
          width: double.infinity,
          height: HomeWeightCard.cardHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.homeWeightGradientStart,
                AppColors.homeWeightGradientEnd,
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.homeWeightShadow,
                offset: Offset(0, 8),
                blurRadius: 20,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.45,
                  child: Align(
                    alignment: const Alignment(2.6, 1.9),
                    child: FractionallySizedBox(
                      widthFactor: 0.78,
                      heightFactor: 0.95,
                      child: Image.asset(
                        HomeWeightCard._mascotAsset,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.homeWeightGradientStart.withValues(
                          alpha: 0.42,
                        ),
                        AppColors.homeWeightGradientEnd.withValues(
                          alpha: 0.58,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.monitor_weight_outlined,
                          size: 18,
                          color: AppColors.surface.withValues(alpha: 0.95),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Peso',
                          style: AppTextStyles.homeSectionTitle.copyWith(
                            color: AppColors.surface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _weightLabel,
                              key: const ValueKey('home-weight-card-value'),
                              style: AppTextStyles.statValue.copyWith(
                                color: AppColors.surface,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                height: 1,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x66000000),
                                    blurRadius: 6,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _currentUnit,
                              style: AppTextStyles.micro.copyWith(
                                color: AppColors.surface.withValues(
                                  alpha: 0.9,
                                ),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _WeightAddButton(
                        onPressed: _weightController.open,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeightAddButton extends StatelessWidget {
  const _WeightAddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Adicionar peso',
      child: Material(
        color: AppColors.surface,
        shape: const CircleBorder(),
        child: InkWell(
          key: const ValueKey('home-weight-add'),
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              Icons.add_rounded,
              color: AppColors.homeWeightGradientEnd,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
