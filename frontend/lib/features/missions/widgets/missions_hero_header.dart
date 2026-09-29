import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_svg_icon.dart';

class MissionsHeroHeader extends StatelessWidget {
  const MissionsHeroHeader({
    super.key,
    required this.gold,
    required this.xp,
    required this.onOpenStore,
    this.onOpenGoldStatement,
  });

  final int gold;
  final int xp;
  final VoidCallback onOpenStore;
  final VoidCallback? onOpenGoldStatement;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(22, topInset + 16, 12, 26),
      decoration: const BoxDecoration(
        color: AppColors.brand300,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    'Missões',
                    style: AppTextStyles.missionsTitle.copyWith(
                      color: AppColors.brand900Variant,
                      fontSize: 28,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
              _HeroBalancePill(
                value: gold.toString(),
                icon: const AppSvgIcon.gold(size: 20),
                onTap: onOpenGoldStatement,
              ),
              const SizedBox(width: 4),
              _HeroBalancePill(
                value: xp.toString(),
                icon: const AppSvgIcon.xp(size: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Text(
              'Troque o ouro das missões na loja por molduras, fundos, figurinhas e proteção de sequência.',
              style: AppTextStyles.missionsTitle.copyWith(
                color: AppColors.brand900Variant,
                fontSize: 21,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: onOpenStore,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand900Variant,
                  foregroundColor: AppColors.surface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                icon: const Icon(Icons.storefront_rounded, size: 20),
                label: Text(
                  'Abrir loja',
                  style: AppTextStyles.missionsCardTitle.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBalancePill extends StatelessWidget {
  const _HeroBalancePill({
    required this.value,
    required this.icon,
    this.onTap,
  });

  final String value;
  final Widget icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              icon,
              const SizedBox(width: 6),
              Text(
                value,
                style: AppTextStyles.missionsPillValue.copyWith(
                  color: AppColors.brand900Variant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
