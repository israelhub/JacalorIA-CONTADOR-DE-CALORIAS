import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/measurement_input_field.dart';
import '../../auth/service/auth_service.dart';

class HomeWeightEditSheet {
  HomeWeightEditSheet._();

  static Future<Map<String, dynamic>?> show({
    required BuildContext context,
    required Map<String, dynamic>? userProfile,
    AuthService? authService,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _HomeWeightEditSheetContent(
        userProfile: userProfile,
        authService: authService ?? AuthService(),
      ),
    );
  }
}

class _HomeWeightEditSheetContent extends StatefulWidget {
  const _HomeWeightEditSheetContent({
    required this.userProfile,
    required this.authService,
  });

  final Map<String, dynamic>? userProfile;
  final AuthService authService;

  @override
  State<_HomeWeightEditSheetContent> createState() =>
      _HomeWeightEditSheetContentState();
}

class _HomeWeightEditSheetContentState extends State<_HomeWeightEditSheetContent> {
  final _weightController = TextEditingController();
  var _selectedWeightUnit = 'kg';
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _hydrateWeight();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _hydrateWeight() {
    final profile = widget.userProfile;
    if (profile == null) {
      return;
    }

    final weight = profile['weight'];
    final weightUnit =
        (profile['weightUnit'] as String?) ??
        (profile['weight_unit'] as String?);

    if (weight is num) {
      _weightController.text = _formatNumber(weight);
    } else if (weight is String && weight.trim().isNotEmpty) {
      final parsedWeight = num.tryParse(weight.replaceAll(',', '.'));
      if (parsedWeight != null) {
        _weightController.text = _formatNumber(parsedWeight);
      }
    }

    _selectedWeightUnit = weightUnit?.trim().isNotEmpty == true
        ? weightUnit!.trim()
        : 'kg';
  }

  String _formatNumber(num value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  Future<void> _saveWeight() async {
    if (_isSaving) {
      return;
    }

    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    if (weight == null || weight <= 0) {
      AppToast.error(context, message: 'Informe um peso válido.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.authService.updateProfile(<String, dynamic>{
        'weight': weight,
        'weightUnit': _selectedWeightUnit,
      });

      if (!mounted) {
        return;
      }

      AppToast.success(context, message: 'Peso atualizado.');
      Navigator.of(context).pop(<String, dynamic>{
        'weight': weight,
        'weightUnit': _selectedWeightUnit,
      });
    } catch (e) {
      if (mounted) {
        AppToast.error(context, message: 'Erro ao salvar peso: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: AppSpacing.xxxl,
                height: AppSpacing.xs,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Atualizar peso',
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.brand900Variant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Registre seu peso atual para manter metas e recomendações precisas.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            MeasurementInputField(
              label: 'Peso',
              hint: 'Digite seu peso',
              controller: _weightController,
              unitSelectorKey: const ValueKey('home-weight-unit-selector'),
              selectedUnit: _selectedWeightUnit,
              unitOptions: const ['kg', 'lb', 'g'],
              onUnitSelected: (unit) {
                setState(() {
                  _selectedWeightUnit = unit;
                });
              },
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: AppSpacing.huge + AppSpacing.xs,
              child: AppButton(
                label: _isSaving ? 'Salvando...' : 'Salvar peso',
                onPressed: _isSaving ? null : _saveWeight,
                variant: AppButtonVariant.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
