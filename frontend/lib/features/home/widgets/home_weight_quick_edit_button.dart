import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_floating_circle_button.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../auth/service/auth_service.dart';

/// Clearance so shell FABs sit above the bottom navigation (extendBody).
const homeShellFabBottomClearance = AppSpacing.huge + AppSpacing.xxxl + AppSpacing.sm;

class HomeWeightQuickEditButton extends StatefulWidget {
  const HomeWeightQuickEditButton({
    super.key,
    required this.userProfile,
    this.authService,
    this.onWeightUpdated,
  });

  final Map<String, dynamic>? userProfile;
  final AuthService? authService;
  final ValueChanged<Map<String, dynamic>>? onWeightUpdated;

  @override
  State<HomeWeightQuickEditButton> createState() =>
      _HomeWeightQuickEditButtonState();
}

class _HomeWeightQuickEditButtonState extends State<HomeWeightQuickEditButton> {
  var _isSaving = false;

  AuthService get _authService => widget.authService ?? AuthService();

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

  String _formatWeight(double value) {
    if (value <= 0) {
      return '';
    }
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  Future<void> _openEditor() async {
    if (_isSaving) {
      return;
    }

    final unit = _currentUnit;
    final newWeight = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => _WeightEditSheet(
        initialText: _formatWeight(_currentWeight),
        weightUnit: unit,
      ),
    );

    if (newWeight != null && newWeight > 0) {
      await _persistWeight(newWeight, unit);
    }
  }

  Future<void> _persistWeight(double weight, String unit) async {
    final current = widget.userProfile;
    final currentWeight = current?['weight'];
    final currentUnit =
        (current?['weightUnit'] as String?) ??
        (current?['weight_unit'] as String?) ??
        'kg';
    final sameWeight = currentWeight is num
        ? currentWeight.toDouble() == weight
        : double.tryParse('$currentWeight'.replaceAll(',', '.')) == weight;
    if (sameWeight && currentUnit == unit) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _authService.updateProfile(<String, dynamic>{
        'weight': weight,
        'weightUnit': unit,
      });
      widget.onWeightUpdated?.call(<String, dynamic>{
        'weight': weight,
        'weightUnit': unit,
      });
      if (mounted) {
        AppToast.success(context, message: 'Peso atualizado.');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, message: 'Erro ao salvar peso: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFloatingCircleButton(
      key: const ValueKey('home-weight-quick-edit-button'),
      icon: Icons.monitor_weight_outlined,
      semanticLabel: 'Atualizar peso',
      onPressed: _openEditor,
    );
  }
}

class _WeightEditSheet extends StatefulWidget {
  const _WeightEditSheet({
    required this.initialText,
    required this.weightUnit,
  });

  final String initialText;
  final String weightUnit;

  @override
  State<_WeightEditSheet> createState() => _WeightEditSheetState();
}

class _WeightEditSheetState extends State<_WeightEditSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText)
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.initialText.length,
      );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _parsedWeight {
    final parsed = double.tryParse(_controller.text.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  void _submit() {
    final weight = _parsedWeight;
    if (weight == null) {
      return;
    }
    Navigator.of(context).pop(weight);
  }

  @override
  Widget build(BuildContext context) {
    // viewInsets lifts the sheet content above the soft keyboard.
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.xl,
            AppSpacing.xxl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Atualizar peso',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.brand900Variant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IntrinsicWidth(
                    child: TextField(
                      key: const ValueKey('home-weight-edit-field'),
                      controller: _controller,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      enableSuggestions: false,
                      autocorrect: false,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        LengthLimitingTextInputFormatter(6),
                      ],
                      style: AppTextStyles.headingLarge.copyWith(
                        color: AppColors.brand900Variant,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        constraints: const BoxConstraints(minWidth: 64),
                        hintText: '0',
                        hintStyle: AppTextStyles.headingLarge.copyWith(
                          color: AppColors.textSecondary.withValues(
                            alpha: 0.45,
                          ),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    widget.weightUnit,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Salvar',
                onPressed: _parsedWeight == null ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
