import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_page_route.dart';
import '../../../shared/widgets/app_toast.dart';
import '../models/home_steps_models.dart';
import '../pages/home_steps_page.dart';
import 'home_steps_card.dart';
import 'home_steps_weight_scope.dart';
import 'home_weight_card.dart';

class HomeStepsWeightRow extends StatelessWidget {
  const HomeStepsWeightRow({super.key, this.onWeightUpdated});

  final ValueChanged<Map<String, dynamic>>? onWeightUpdated;

  static const double height = HomeStepsCard.cardHeight;

  @override
  Widget build(BuildContext context) {
    final controller = HomeStepsWeightScope.maybeOf(context);
    if (controller == null) {
      return const SizedBox.shrink();
    }

    return Row(
      key: const ValueKey('home-steps-weight-row'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: HomeStepsCard(
            overview: controller.steps,
            isLoading: controller.isStepsLoading,
            onActivate: () => _activateSteps(context),
            onOpenDetails: () => _openDetails(context),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: HomeWeightCard(
            userProfile: controller.userProfile,
            onWeightUpdated: (profile) {
              unawaited(() async {
                await controller.applyWeightUpdate(profile);
                onWeightUpdated?.call(profile);
              }());
            },
          ),
        ),
      ],
    );
  }

  void _openDetails(BuildContext context) {
    unawaited(context.pushSlidePage(const HomeStepsPage()));
  }

  Future<void> _activateSteps(BuildContext context) async {
    final controller = HomeStepsWeightScope.of(context);
    final status = await controller.activateTracking();
    if (!context.mounted) {
      return;
    }
    switch (status) {
      case HomeStepsStatus.ready:
        AppToast.success(context, message: 'Contagem de passos ativada.');
        return;
      case HomeStepsStatus.needsHealthConnect:
        AppToast.show(
          context,
          message:
              'Instale o Health Connect para sincronizar com o Samsung Health.',
        );
        return;
      case HomeStepsStatus.needsPermission:
        AppToast.error(
          context,
          message: 'Permissão necessária para contar seus passos.',
        );
        return;
      case HomeStepsStatus.unsupported:
        AppToast.show(
          context,
          message: 'A contagem de passos está disponível no app mobile.',
        );
        return;
      case HomeStepsStatus.unavailable:
        AppToast.error(
          context,
          message: 'Não foi possível ativar a contagem de passos.',
        );
        return;
    }
  }
}
