import 'package:flutter/material.dart';

import 'objective_page.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';

class PersonalDataPage extends StatefulWidget {
  const PersonalDataPage({super.key});

  @override
  State<PersonalDataPage> createState() => _PersonalDataPageState();
}

class _PersonalDataPageState extends State<PersonalDataPage> {
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final GlobalKey _sexFieldKey = GlobalKey();

  String? _selectedSex;

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
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brand900,
              ),
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

  InputDecoration _fieldDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
      isDense: true,
      filled: true,
      fillColor: AppColors.surface,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: AppColors.borderAlt),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: AppColors.borderAlt),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: AppColors.borderAlt),
      ),
    );
  }

  Widget _fieldContainer({required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowButtonAlt,
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }

  Future<void> _openSexMenu() async {
    final fieldContext = _sexFieldKey.currentContext;
    if (fieldContext == null) {
      return;
    }

    final fieldBox = fieldContext.findRenderObject() as RenderBox?;
    final overlayBox = Overlay.of(context).context.findRenderObject() as RenderBox?;

    if (fieldBox == null || overlayBox == null) {
      return;
    }

    final fieldOffset = fieldBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final fieldRect = Rect.fromLTWH(
      fieldOffset.dx,
      fieldOffset.dy,
      fieldBox.size.width,
      fieldBox.size.height,
    );
    final menuItemWidth = fieldRect.width;

    final selectedValue = await showMenu<String>(
      context: context,
      color: AppColors.surface,
      elevation: 2,
      constraints: BoxConstraints.tightFor(width: menuItemWidth),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      position: RelativeRect.fromLTRB(
        fieldRect.left,
        fieldRect.bottom + AppSpacing.xs,
        overlayBox.size.width - fieldRect.right,
        overlayBox.size.height - fieldRect.bottom,
      ),
      items: _sexOptions
          .map(
            (option) => PopupMenuItem<String>(
              value: option,
              height: AppSpacing.huge + AppSpacing.lg,
              padding: EdgeInsets.zero,
              child: SizedBox(
                width: menuItemWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      option,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );

    if (selectedValue == null) {
      return;
    }

    setState(() {
      _selectedSex = selectedValue;
    });
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: AppSpacing.huge,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                        icon: const Icon(Icons.arrow_back),
                        color: AppColors.brand900,
                        splashRadius: AppSpacing.xl,
                      ),
                    ),
                    SizedBox(
                      width: AppSpacing.huge * 7,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: AppSpacing.xs,
                              decoration: BoxDecoration(
                                color: AppColors.brand900,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Container(
                              height: AppSpacing.xs,
                              decoration: BoxDecoration(
                                color: AppColors.borderAlt,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Container(
                              height: AppSpacing.xs,
                              decoration: BoxDecoration(
                                color: AppColors.borderAlt,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Text(
                'Dados pessoais',
                style: AppTextStyles.headingLarge.copyWith(
                  color: AppColors.brand900Variant,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Text(
                'Data de nascimento',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _fieldContainer(
                child: TextField(
                  key: const ValueKey('personal-birthdate-field'),
                  controller: _birthDateController,
                  readOnly: true,
                  onTap: _pickBirthDate,
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
                  decoration: _fieldDecoration(
                    hint: 'Selecione sua data de nascimento',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today_outlined),
                      color: AppColors.textSecondary,
                      onPressed: _pickBirthDate,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Peso',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _fieldContainer(
                child: TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
                  decoration: _fieldDecoration(hint: 'Digite seu peso'),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Altura',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _fieldContainer(
                child: TextField(
                  controller: _heightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
                  decoration: _fieldDecoration(hint: 'Digite sua altura'),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Sexo',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              KeyedSubtree(
                key: _sexFieldKey,
                child: _fieldContainer(
                  child: InkWell(
                  key: const ValueKey('personal-sex-field'),
                  onTap: _openSexMenu,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: InputDecorator(
                    decoration: _fieldDecoration(
                      hint: 'Selecione seu sexo',
                      suffixIcon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedSex ?? 'Selecione seu sexo',
                            style: (_selectedSex == null
                                    ? AppTextStyles.bodyLarge.copyWith(
                                        color: AppColors.textSecondary,
                                      )
                                    : AppTextStyles.bodyLarge.copyWith(
                                        color: AppColors.textPrimary,
                                      ))
                                .copyWith(overflow: TextOverflow.ellipsis),
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
                ),
              ),
              const SizedBox(height: AppSpacing.huge + AppSpacing.xxl),
              Center(
                child: SizedBox(
                  width: (AppSpacing.huge * 5) + AppSpacing.xl + AppSpacing.xs + (AppSpacing.xs / 2),
                  height: AppSpacing.huge + AppSpacing.xs,
                  child: AppButton(
                    label: 'Avançar',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ObjectivePage(),
                        ),
                      );
                    },
                    variant: AppButtonVariant.primary,
                  ),
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
