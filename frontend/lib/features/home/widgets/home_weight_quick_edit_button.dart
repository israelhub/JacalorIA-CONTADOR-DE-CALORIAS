import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/theme/app_theme.dart';
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
  final TextEditingController _weightController = TextEditingController();
  var _isExpanded = false;
  var _isSaving = false;
  var _isEditingText = false;
  double _weight = 0;
  var _weightUnit = 'kg';

  AuthService get _authService => widget.authService ?? AuthService();

  @override
  void initState() {
    super.initState();
    _hydrateFromProfile();
  }

  @override
  void didUpdateWidget(covariant HomeWeightQuickEditButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isExpanded && oldWidget.userProfile != widget.userProfile) {
      _hydrateFromProfile();
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _hydrateFromProfile() {
    final profile = widget.userProfile;
    final rawWeight = profile?['weight'];
    final unit =
        (profile?['weightUnit'] as String?) ??
        (profile?['weight_unit'] as String?);

    double parsed = 0;
    if (rawWeight is num) {
      parsed = rawWeight.toDouble();
    } else if (rawWeight is String && rawWeight.trim().isNotEmpty) {
      parsed = double.tryParse(rawWeight.replaceAll(',', '.')) ?? 0;
    }

    _weight = parsed > 0 ? parsed : 0;
    _weightUnit = unit?.trim().isNotEmpty == true ? unit!.trim() : 'kg';
    _weightController.text = _formatWeight(_weight);
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

  double get _step {
    switch (_weightUnit) {
      case 'lb':
        return 1;
      case 'g':
        return 100;
      case 'kg':
      default:
        return 0.1;
    }
  }

  Future<void> _toggle() async {
    if (_isExpanded) {
      if (_isEditingText) {
        _applyEditedWeightLocally();
      }
      setState(() => _isExpanded = false);
      await _persistWeight();
      return;
    }

    _hydrateFromProfile();
    setState(() {
      _isEditingText = false;
      _weightController.text = _formatWeight(_weight);
      _isExpanded = true;
    });
  }

  void _adjustWeight(double delta) {
    if (_isSaving) {
      return;
    }
    final next = ((_weight + delta) * 10).roundToDouble() / 10;
    if (next <= 0) {
      return;
    }
    setState(() {
      _weight = next;
      _isEditingText = false;
      _weightController.text = _formatWeight(_weight);
    });
  }

  void _startEditing() {
    if (_isSaving) {
      return;
    }
    setState(() {
      _isEditingText = true;
      _weightController.text = _formatWeight(_weight);
      _weightController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _weightController.text.length,
      );
    });
  }

  void _applyEditedWeightLocally() {
    final parsed = double.tryParse(_weightController.text.replaceAll(',', '.'));
    if (parsed != null && parsed > 0) {
      _weight = parsed;
    }
    _isEditingText = false;
    _weightController.text = _formatWeight(_weight);
  }

  void _submitEditedWeight() {
    setState(_applyEditedWeightLocally);
  }

  Future<void> _persistWeight() async {
    if (_isSaving || _weight <= 0) {
      return;
    }

    final current = widget.userProfile;
    final currentWeight = current?['weight'];
    final currentUnit =
        (current?['weightUnit'] as String?) ??
        (current?['weight_unit'] as String?) ??
        'kg';
    final sameWeight = currentWeight is num
        ? currentWeight.toDouble() == _weight
        : double.tryParse('$currentWeight'.replaceAll(',', '.')) == _weight;
    if (sameWeight && currentUnit == _weightUnit) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _authService.updateProfile(<String, dynamic>{
        'weight': _weight,
        'weightUnit': _weightUnit,
      });
      widget.onWeightUpdated?.call(<String, dynamic>{
        'weight': _weight,
        'weightUnit': _weightUnit,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.25),
                  end: Offset.zero,
                ).animate(animation),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1).animate(animation),
                  child: child,
                ),
              ),
            );
          },
          child: _isExpanded
              ? Padding(
                  key: const ValueKey('weight-controls'),
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _WeightControls(
                    weightText: _formatWeight(_weight),
                    weightUnit: _weightUnit,
                    controller: _weightController,
                    isEditingText: _isEditingText,
                    isSaving: _isSaving,
                    onDecrease: () => _adjustWeight(-_step),
                    onIncrease: () => _adjustWeight(_step),
                    onStartEdit: _startEditing,
                    onSubmitEdit: _submitEditedWeight,
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('weight-controls-hidden')),
        ),
        AppFloatingCircleButton(
          key: const ValueKey('home-weight-quick-edit-button'),
          icon: _isExpanded
              ? Icons.close_rounded
              : Icons.monitor_weight_outlined,
          semanticLabel: _isExpanded ? 'Fechar edição de peso' : 'Atualizar peso',
          onPressed: _toggle,
        ),
      ],
    );
  }
}

class _WeightControls extends StatelessWidget {
  const _WeightControls({
    required this.weightText,
    required this.weightUnit,
    required this.controller,
    required this.isEditingText,
    required this.isSaving,
    required this.onDecrease,
    required this.onIncrease,
    required this.onStartEdit,
    required this.onSubmitEdit,
  });

  final String weightText;
  final String weightUnit;
  final TextEditingController controller;
  final bool isEditingText;
  final bool isSaving;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onStartEdit;
  final VoidCallback onSubmitEdit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.borderBrand),
          boxShadow: AppShadows.md,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppFloatingCircleButton(
              icon: Icons.remove_rounded,
              size: 44,
              iconSize: 22,
              semanticLabel: 'Diminuir peso',
              onPressed: onDecrease,
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 72,
              child: isEditingText
                  ? TextField(
                      controller: controller,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppColors.brand900Variant,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => onSubmitEdit(),
                      onTapOutside: (_) => onSubmitEdit(),
                    )
                  : InkWell(
                      onTap: isSaving ? null : onStartEdit,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              weightText.isEmpty ? '--' : weightText,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.headingSmall.copyWith(
                                color: AppColors.brand900Variant,
                              ),
                            ),
                            Text(
                              weightUnit,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppFloatingCircleButton(
              icon: Icons.add_rounded,
              size: 44,
              iconSize: 22,
              semanticLabel: 'Aumentar peso',
              onPressed: onIncrease,
            ),
          ],
        ),
      ),
    );
  }
}
