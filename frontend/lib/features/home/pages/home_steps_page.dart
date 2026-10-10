import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_back_page_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_form_card.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/app_toast.dart';
import '../helpers/home_steps_helpers.dart';
import '../models/home_steps_models.dart';
import '../widgets/home_shell_layout.dart';
import '../widgets/home_steps_card.dart';
import '../widgets/home_steps_weight_scope.dart';

class HomeStepsPage extends StatefulWidget {
  const HomeStepsPage({super.key});

  @override
  State<HomeStepsPage> createState() => _HomeStepsPageState();
}

class _HomeStepsPageState extends State<HomeStepsPage> {
  final _goalController = TextEditingController();
  String? _error;
  var _isSaving = false;
  var _goalSeeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_goalSeeded) {
      return;
    }
    _goalSeeded = true;
    final goal = HomeStepsWeightScope.of(context).steps.goalSteps;
    _goalController.text = clampDailyStepsGoal(goal).toString();
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  int? get _parsedGoal {
    final raw = _goalController.text.trim().replaceAll('.', '');
    if (raw.isEmpty) {
      return null;
    }
    return int.tryParse(raw);
  }

  Future<void> _activate() async {
    final controller = HomeStepsWeightScope.of(context);
    final status = await controller.activateTracking();
    if (!mounted) {
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

  Future<void> _saveGoal([int? preset]) async {
    final goal = preset ?? _parsedGoal;
    if (goal == null) {
      setState(() {
        _error = 'Informe a meta de passos.';
      });
      return;
    }
    if (goal < minDailyStepsGoal || goal > maxDailyStepsGoal) {
      setState(() {
        _error =
            'Use entre ${formatStepsCount(minDailyStepsGoal)} e ${formatStepsCount(maxDailyStepsGoal)}.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });
    final saved = await HomeStepsWeightScope.of(
      context,
    ).setGoal(clampDailyStepsGoal(goal));
    if (!mounted) {
      return;
    }
    setState(() {
      _isSaving = false;
      if (saved != null) {
        _goalController.text = saved.toString();
      }
    });
    if (saved == null) {
      AppToast.error(context, message: 'Não foi possível salvar a meta.');
      return;
    }
    AppToast.success(
      context,
      message: 'Meta de ${formatStepsCount(saved)} passos salva.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = HomeStepsWeightScope.of(context);
    final overview = controller.steps;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      extendBodyBehindAppBar: true,
      appBar: const AppBackPageHeader(title: 'Passos'),
      body: AppBackPageContent(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppBackPageHeader.scrollTopInset(context, extra: AppSpacing.lg),
            AppSpacing.pageHorizontal,
            homeShellScrollBottomInset(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeStepsCard(
                overview: overview,
                isLoading: controller.isStepsLoading,
                expanded: true,
                onActivate: overview.canRequestAccess ? _activate : null,
              ),
              const SizedBox(height: AppSpacing.cardGap),
              AppFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Meta diária',
                      style: AppTextStyles.homeSectionTitle.copyWith(
                        color: AppColors.brand900Variant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppInput(
                      key: const ValueKey('home-steps-goal-field'),
                      controller: _goalController,
                      hintText: 'Ex.: 10000',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      showBorder: true,
                      showShadow: false,
                      onChanged: (_) {
                        if (_error != null) {
                          setState(() => _error = null);
                        }
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _error!,
                        style: AppTextStyles.micro.copyWith(
                          color: AppColors.textError,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      key: const ValueKey('home-steps-goal-save'),
                      label: 'Salvar meta',
                      onPressed: _isSaving ? null : () => _saveGoal(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
