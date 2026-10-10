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
  static const Color _accent = AppColors.action500;

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
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.homeCardSurface,
            borderRadius: radius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Peso',
                style: AppTextStyles.homeSectionTitle.copyWith(
                  color: AppColors.brand900Variant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _weightLabel,
                        key: const ValueKey('home-weight-card-value'),
                        style: AppTextStyles.statValue.copyWith(
                          color: AppColors.brand900Variant,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        _currentUnit,
                        style: AppTextStyles.micro.copyWith(
                          color: AppColors.textSecondary,
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
        color: HomeWeightCard._accent,
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
              color: AppColors.surface,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
