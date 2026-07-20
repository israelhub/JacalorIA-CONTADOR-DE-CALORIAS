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
  final FocusNode _weightFocusNode = FocusNode();
  var _isExpanded = false;
  var _isSaving = false;
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
    _weightFocusNode.dispose();
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

  Future<void> _toggle() async {
    if (_isExpanded) {
      await _finishEditing();
      return;
    }

    _hydrateFromProfile();
    setState(() {
      _weightController.text = _formatWeight(_weight);
      _isExpanded = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _weightFocusNode.requestFocus();
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
    _weightController.text = _formatWeight(_weight);
  }

  Future<void> _finishEditing() async {
    if (!_isExpanded || _isSaving) {
      return;
    }
    _weightFocusNode.unfocus();
    _applyEditedWeightLocally();
    setState(() => _isExpanded = false);
    await _persistWeight();
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
                  child: _WeightInputPanel(
                    weightUnit: _weightUnit,
                    controller: _weightController,
                    focusNode: _weightFocusNode,
                    isSaving: _isSaving,
                    onSubmitted: _finishEditing,
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('weight-controls-hidden')),
        ),
        AppFloatingCircleButton(
          key: const ValueKey('home-weight-quick-edit-button'),
          icon: _isExpanded
              ? Icons.check_rounded
              : Icons.monitor_weight_outlined,
          semanticLabel: _isExpanded ? 'Salvar peso' : 'Atualizar peso',
          onPressed: _toggle,
        ),
      ],
    );
  }
}

class _WeightInputPanel extends StatelessWidget {
  const _WeightInputPanel({
    required this.weightUnit,
    required this.controller,
    required this.focusNode,
    required this.isSaving,
    required this.onSubmitted,
  });

  final String weightUnit;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSaving;
  final Future<void> Function() onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        width: 148,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.borderBrand),
          boxShadow: AppShadows.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: !isSaving,
              autofocus: true,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              enableSuggestions: false,
              autocorrect: false,
              // Keeps the field visible above the soft keyboard on small screens.
              scrollPadding: const EdgeInsets.only(bottom: 120),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                LengthLimitingTextInputFormatter(6),
              ],
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.brand900Variant,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: '0',
                hintStyle: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.45),
                ),
              ),
              onSubmitted: (_) => onSubmitted(),
              // Only dismiss the keyboard — save/close via Done or the check FAB,
              // otherwise tapping the FAB would collapse then immediately reopen.
              onTapOutside: (_) => focusNode.unfocus(),
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
    );
  }
}
