import 'package:flutter/material.dart';
import '../../../shared/widgets/app_page_route.dart';

import 'objective_page.dart';
import '../widgets/onboarding_input_field.dart';
import '../widgets/onboarding_step_header.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/measurement_input_field.dart';
import '../../../shared/widgets/app_select_input_field.dart';

class PersonalDataPage extends StatefulWidget {
  const PersonalDataPage({super.key});

  @override
  State<PersonalDataPage> createState() => _PersonalDataPageState();
}

class _PersonalDataPageState extends State<PersonalDataPage> {
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  String? _selectedSex;
  String _selectedWeightUnit = 'kg';
  String _selectedHeightUnit = 'cm';

  static const List<String> _sexOptions = [
    'Masculino',
    'Feminino',
    'Demais',
    'Prefiro não informar',
  ];

  @override
  void dispose() {
    _birthDateController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initialDate = DateTime(now.year - 18, now.month, now.day);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        final theme = Theme.of(context);

        return Theme(
          data: theme.copyWith(
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.surface,
            ),
            colorScheme: theme.colorScheme.copyWith(
              primary: AppColors.brand300,
              onPrimary: AppColors.brand900Variant,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: AppColors.surface,
              surfaceTintColor: AppColors.surface,
              headerBackgroundColor: AppColors.brand300,
              headerForegroundColor: AppColors.brand900Variant,
              dayForegroundColor: const WidgetStatePropertyAll(
                AppColors.textPrimary,
              ),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.brand300;
                }
                return AppColors.surface;
              }),
              todayForegroundColor: const WidgetStatePropertyAll(
                AppColors.brand900,
              ),
              todayBackgroundColor: const WidgetStatePropertyAll(
                AppColors.brand300,
              ),
              yearForegroundColor: const WidgetStatePropertyAll(
                AppColors.textPrimary,
              ),
              yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.brand300;
                }
                return AppColors.surface;
              }),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.brand900),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (selectedDate == null) {
      return;
    }

    final day = selectedDate.day.toString().padLeft(2, '0');
    final month = selectedDate.month.toString().padLeft(2, '0');
    final year = selectedDate.year.toString();

    _birthDateController.text = '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final pageTheme = Theme.of(context).copyWith(
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.brand900,
        selectionColor: AppColors.brand300,
        selectionHandleColor: AppColors.brand900,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Theme(
          data: pageTheme,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),
                OnboardingStepHeader(
                  activeStep: 1,
                  onBack: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.xxxl),
                Text(
                  'Dados pessoais',
                  style: AppTextStyles.headingLarge.copyWith(
                    color: AppColors.brand900Variant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                AppInputField(
                  key: const ValueKey('personal-birthdate-field'),
                  label: 'Data de nascimento',
                  hint: 'Selecione sua data de nascimento',
                  controller: _birthDateController,
                  readOnly: true,
                  onTap: _pickBirthDate,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today_outlined),
                    color: AppColors.textSecondary,
                    onPressed: _pickBirthDate,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                MeasurementInputField(
                  label: 'Peso',
                  hint: 'Digite seu peso',
                  controller: _weightController,
                  unitSelectorKey: const ValueKey(
                    'personal-weight-unit-selector',
                  ),
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
                const SizedBox(height: AppSpacing.xxl),
                MeasurementInputField(
                  label: 'Altura',
                  hint: 'Digite sua altura',
                  controller: _heightController,
                  unitSelectorKey: const ValueKey(
                    'personal-height-unit-selector',
                  ),
                  selectedUnit: _selectedHeightUnit,
                  unitOptions: const ['cm', 'm', 'ft', 'in'],
                  onUnitSelected: (unit) {
                    setState(() {
                      _selectedHeightUnit = unit;
                    });
                  },
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                OnboardingInputField(
                  label: 'Sexo',
                  child: AppSelectInputField(
                    fieldKey: const ValueKey('personal-sex-field'),
                    label: '',
                    hint: 'Selecione seu sexo',
                    selectedValue: _selectedSex ?? '',
                    options: _sexOptions,
                    onSelected: (value) {
                      setState(() {
                        _selectedSex = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.huge + AppSpacing.xxl),
                SizedBox(
                  key: const ValueKey('personal-next-button-box'),
                  width: double.infinity,
                  height: AppSpacing.huge + AppSpacing.xs,
                  child: AppButton(
                    label: 'Avançar',
                    onPressed: () {
                      final birthDate = _birthDateController.text;
                      final weight =
                          double.tryParse(_weightController.text) ?? 0.0;
                      final height =
                          double.tryParse(_heightController.text) ?? 0.0;
                      final sex = _selectedSex;

                      String? formattedBirthDate;
                      if (birthDate.isNotEmpty) {
                        try {
                          final parts = birthDate.split('/');
                          if (parts.length == 3) {
                            formattedBirthDate =
                                '${parts[2]}-${parts[1]}-${parts[0]}';
                          }
                        } catch (_) {}
                      }

                      final data = <String, dynamic>{
                        if (formattedBirthDate != null)
                          'birthDate': formattedBirthDate,
                        if (weight > 0) 'weight': weight,
                        if (height > 0) 'height': height,
                        'weightUnit': _selectedWeightUnit,
                        'heightUnit': _selectedHeightUnit,
                        if (sex != null) 'sex': sex,
                      };

                      context.pushSlidePage(
                        ObjectivePage(onboardingData: data),
                      );
                    },
                    variant: AppButtonVariant.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
