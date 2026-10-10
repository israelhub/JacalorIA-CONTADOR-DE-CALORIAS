import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_modal.dart';
import '../helpers/home_steps_helpers.dart';

Future<int?> showHomeStepsGoalSheet(
  BuildContext context, {
  required int currentGoal,
}) {
  return showDialog<int>(
    context: context,
    builder: (context) {
      return _HomeStepsGoalSheet(currentGoal: currentGoal);
    },
  );
}

class _HomeStepsGoalSheet extends StatefulWidget {
  const _HomeStepsGoalSheet({required this.currentGoal});

  final int currentGoal;

  @override
  State<_HomeStepsGoalSheet> createState() => _HomeStepsGoalSheetState();
}

class _HomeStepsGoalSheetState extends State<_HomeStepsGoalSheet> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: clampDailyStepsGoal(widget.currentGoal).toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _parsedGoal {
    final raw = _controller.text.trim().replaceAll('.', '');
    if (raw.isEmpty) {
      return null;
    }
    return int.tryParse(raw);
  }

  void _submit([int? preset]) {
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
    Navigator.of(context).pop(clampDailyStepsGoal(goal));
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meta de passos',
            style: AppTextStyles.missionsSectionTitle.copyWith(
              color: AppColors.brand900Variant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'O contador começa na meta e vai diminuindo até o restante do dia.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...homeStepsGoalPresets.map(
            (amount) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(
                '👣',
                style: AppTextStyles.bodyMedium.copyWith(fontSize: 18),
              ),
              title: Text(formatStepsCount(amount)),
              trailing: amount == clampDailyStepsGoal(widget.currentGoal)
                  ? const Icon(Icons.check_rounded, color: AppColors.brand900)
                  : null,
              onTap: () => _submit(amount),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            key: const ValueKey('home-steps-goal-field'),
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Meta personalizada',
              errorText: _error,
              suffixText: 'passos',
            ),
            onChanged: (_) {
              if (_error != null) {
                setState(() {
                  _error = null;
                });
              }
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const ValueKey('home-steps-goal-save'),
              onPressed: _submit,
              child: const Text('Salvar meta'),
            ),
          ),
        ],
      ),
    );
  }
}
