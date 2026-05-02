import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/helpers/nutrition_goal_calculator.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input.dart';
import '../../../../shared/widgets/app_page_route.dart';
import '../../../../shared/widgets/app_select_input_field.dart';
import '../../../../shared/widgets/measurement_input_field.dart';
import '../../../../shared/services/supabase_storage_service.dart';
import '../../auth/pages/enter_page.dart';
import '../../auth/service/auth_service.dart';
import '../helpers/profile_date_helpers.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.initialProfile});

  final Map<String, dynamic>? initialProfile;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _sexController = TextEditingController();
  final _objectiveController = TextEditingController();
  final _activityController = TextEditingController();

  String? _selectedSex;
  String? _selectedObjective;
  String? _selectedActivityLevel;
  String? _avatarUrl;
  String _selectedWeightUnit = 'kg';
  String _selectedHeightUnit = 'cm';
  bool _isSaving = false;
  bool _isSigningOut = false;
  bool _isContentReady = false;

  static const List<String> _sexOptions = [
    'Masculino',
    'Feminino',
    'Demais',
    'Prefiro não informar',
  ];

  static const Map<String, String> _objectiveLabels = {
    'loseWeight': 'Emagrecer',
    'gainMass': 'Ganhar massa',
    'maintainWeight': 'Manter peso',
  };

  static const Map<String, String> _activityLabels = {
    'sedentary': 'Sedentário',
    'lightly': 'Levemente ativo',
    'moderate': 'Moderadamente ativo',
    'very': 'Muito ativo',
    'extreme': 'Extremamente ativo',
  };

  @override
  void initState() {
    super.initState();
    _hydrateProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isContentReady = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _sexController.dispose();
    _objectiveController.dispose();
    _activityController.dispose();
    super.dispose();
  }

  void _hydrateProfile() {
    final profile = widget.initialProfile ?? <String, dynamic>{};

    _nameController.text = (profile['name'] as String?) ?? '';
    _avatarUrl =
        (profile['avatarUrl'] as String?) ?? (profile['avatar_url'] as String?);

    final birthDateRaw =
        (profile['birthDate'] as String?) ?? (profile['birth_date'] as String?);
    if (birthDateRaw != null && birthDateRaw.isNotEmpty) {
      _birthDateController.text = formatProfileDisplayDate(birthDateRaw);
    }

    final weight = profile['weight'];
    final height = profile['height'];
    final weightUnit =
        (profile['weightUnit'] as String?) ??
        (profile['weight_unit'] as String?);
    final heightUnit =
        (profile['heightUnit'] as String?) ??
        (profile['height_unit'] as String?);

    if (weight is num) {
      _weightController.text = _formatNumber(weight);
    } else if (weight is String && weight.trim().isNotEmpty) {
      final parsedWeight = num.tryParse(weight.replaceAll(',', '.'));
      if (parsedWeight != null) {
        _weightController.text = _formatNumber(parsedWeight);
      }
    }
    if (height is num) {
      _heightController.text = _formatNumber(height);
    } else if (height is String && height.trim().isNotEmpty) {
      final parsedHeight = num.tryParse(height.replaceAll(',', '.'));
      if (parsedHeight != null) {
        _heightController.text = _formatNumber(parsedHeight);
      }
    }

    _selectedWeightUnit = weightUnit?.trim().isNotEmpty == true
        ? weightUnit!.trim()
        : 'kg';
    _selectedHeightUnit = heightUnit?.trim().isNotEmpty == true
        ? heightUnit!.trim()
        : 'cm';

    _selectedSex = profile['sex'] as String?;
    _selectedObjective = profile['objective'] as String?;
    _selectedActivityLevel =
        (profile['activityLevel'] as String?) ??
        (profile['activity_level'] as String?);

    _sexController.text = _selectedSex ?? '';
    _objectiveController.text = _objectiveLabels[_selectedObjective] ?? '';
    _activityController.text = _activityLabels[_selectedActivityLevel] ?? '';
  }

  String _formatNumber(num value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initialDate = DateTime(now.year - 18, now.month, now.day);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (selectedDate == null) {
      return;
    }

    final day = selectedDate.day.toString().padLeft(2, '0');
    final month = selectedDate.month.toString().padLeft(2, '0');
    final year = selectedDate.year.toString();

    _birthDateController.text = '$day/$month/$year';
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final avatarBytes = await picked.readAsBytes();
      final fileName = picked.name.trim().toLowerCase();
      final dotIndex = fileName.lastIndexOf('.');
      final extension = dotIndex > -1 ? fileName.substring(dotIndex) : null;
      final uploadedUrl = await SupabaseStorageService.uploadAvatarBytes(
        avatarBytes,
        extension: extension,
      );
      if (uploadedUrl == null || uploadedUrl.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falha ao enviar foto de perfil.')),
          );
        }
        return;
      }

      setState(() {
        _avatarUrl = uploadedUrl;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _appendNutritionGoals(Map<String, dynamic> data) {
    final weight =
        (data['weight'] as num?)?.toDouble() ??
        double.tryParse(_weightController.text.replaceAll(',', '.')) ??
        70.0;
    final height =
        (data['height'] as num?)?.toDouble() ??
        double.tryParse(_heightController.text.replaceAll(',', '.')) ??
        170.0;
    final weightUnit = (data['weightUnit'] as String?) ?? _selectedWeightUnit;
    final heightUnit = (data['heightUnit'] as String?) ?? _selectedHeightUnit;
    final sex = (data['sex'] as String?) ?? _selectedSex ?? 'Masculino';
    final objective =
        (data['objective'] as String?) ??
        _selectedObjective ??
        'maintainWeight';
    final activity =
        (data['activityLevel'] as String?) ??
        _selectedActivityLevel ??
        'sedentary';

    final age = calculateAgeFromBirthDate(
      (data['birthDate'] as String?) ??
          toProfileApiDate(_birthDateController.text),
    );
    final goals = calculateNutritionGoals(
      NutritionGoalInput(
        weight: weight,
        height: height,
        age: age,
        sex: sex,
        objective: objective,
        activityLevel: activity,
        weightUnit: weightUnit,
        heightUnit: heightUnit,
      ),
    );

    data['dailyCalorieGoal'] = goals.dailyCalorieGoal;
    data['dailyProteinGoal'] = goals.dailyProteinGoal;
    data['dailyCarbsGoal'] = goals.dailyCarbsGoal;
    data['dailyFatGoal'] = goals.dailyFatGoal;
  }

  Future<void> _saveProfile() async {
    if (_isSaving) {
      return;
    }

    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    final height = double.tryParse(_heightController.text.replaceAll(',', '.'));

    final data = <String, dynamic>{
      if (_nameController.text.trim().isNotEmpty)
        'name': _nameController.text.trim(),
      if (toProfileApiDate(_birthDateController.text) != null)
        'birthDate': toProfileApiDate(_birthDateController.text),
      if (weight != null && weight > 0) 'weight': weight,
      if (height != null && height > 0) 'height': height,
      'weightUnit': _selectedWeightUnit,
      'heightUnit': _selectedHeightUnit,
      if (_selectedActivityLevel != null)
        'activityLevel': _selectedActivityLevel,
      if (_selectedSex != null) 'sex': _selectedSex,
      if (_selectedObjective != null) 'objective': _selectedObjective,
      if (_avatarUrl != null && _avatarUrl!.isNotEmpty) 'avatarUrl': _avatarUrl,
    };

    _appendNutritionGoals(data);

    setState(() {
      _isSaving = true;
    });

    try {
      await _authService.updateProfile(data);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar perfil: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    if (_isSigningOut || _isSaving) {
      return;
    }

    setState(() {
      _isSigningOut = true;
    });

    try {
      await _authService.signOut();
      if (!mounted) {
        return;
      }

      context.pushAndRemoveUntilSlidePage(const EnterPage(), (route) => false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao sair: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _avatarUrl;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        title: Text(
          'Perfil',
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.brand900Variant,
          ),
        ),
      ),
      body: SafeArea(
        child: AnimatedOpacity(
          opacity: _isContentReady ? 1 : 0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          child: AnimatedSlide(
            offset: _isContentReady ? Offset.zero : const Offset(0, 0.02),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: GestureDetector(
                      onTap: _pickAvatar,
                      child: Column(
                        children: [
                          ClipOval(
                            child: Container(
                              width: AppSpacing.huge * 2,
                              height: AppSpacing.huge * 2,
                              color: AppColors.surfaceAlt,
                              child: avatarUrl != null && avatarUrl.isNotEmpty
                                  ? Image.network(
                                      avatarUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.person,
                                        size: AppSpacing.huge,
                                        color: AppColors.textSecondary,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: AppSpacing.huge,
                                      color: AppColors.textSecondary,
                                    ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Alterar foto',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.action500,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AppInputField(
                    label: 'Nome',
                    hint: 'Digite seu nome',
                    controller: _nameController,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppInputField(
                    label: 'Data de nascimento',
                    hint: 'Selecione sua data de nascimento',
                    controller: _birthDateController,
                    readOnly: true,
                    onTap: _pickBirthDate,
                    suffixIcon: IconButton(
                      onPressed: _pickBirthDate,
                      color: AppColors.textSecondary,
                      icon: const Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  MeasurementInputField(
                    label: 'Peso',
                    hint: 'Digite seu peso',
                    controller: _weightController,
                    unitSelectorKey: const ValueKey(
                      'profile-weight-unit-selector',
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
                  const SizedBox(height: AppSpacing.lg),
                  MeasurementInputField(
                    label: 'Altura',
                    hint: 'Digite sua altura',
                    controller: _heightController,
                    unitSelectorKey: const ValueKey(
                      'profile-height-unit-selector',
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
                  const SizedBox(height: AppSpacing.lg),
                  AppSelectInputField(
                    fieldKey: const ValueKey('profile-activity-field'),
                    label: 'Nível de atividade',
                    hint: 'Selecione seu nível de atividade',
                    selectedValue: _activityController.text,
                    options: _activityLabels.values.toList(),
                    onSelected: (value) {
                      final entry = _activityLabels.entries.firstWhere(
                        (entry) => entry.value == value,
                        orElse: () => const MapEntry('sedentary', 'Sedentário'),
                      );
                      setState(() {
                        _selectedActivityLevel = entry.key;
                        _activityController.text = entry.value;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppSelectInputField(
                    fieldKey: const ValueKey('profile-sex-field'),
                    label: 'Sexo',
                    hint: 'Selecione seu sexo',
                    selectedValue: _selectedSex ?? '',
                    options: _sexOptions,
                    onSelected: (value) {
                      setState(() {
                        _selectedSex = value;
                        _sexController.text = value;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppSelectInputField(
                    fieldKey: const ValueKey('profile-objective-field'),
                    label: 'Objetivo',
                    hint: 'Selecione seu objetivo',
                    selectedValue: _objectiveController.text,
                    options: _objectiveLabels.values.toList(),
                    onSelected: (value) {
                      final entry = _objectiveLabels.entries.firstWhere(
                        (entry) => entry.value == value,
                        orElse: () =>
                            const MapEntry('maintainWeight', 'Manter peso'),
                      );
                      setState(() {
                        _selectedObjective = entry.key;
                        _objectiveController.text = entry.value;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  SizedBox(
                    height: AppSpacing.huge + AppSpacing.xs,
                    child: AppButton(
                      label: _isSaving ? 'Salvando...' : 'Salvar',
                      onPressed: (_isSaving || _isSigningOut)
                          ? null
                          : _saveProfile,
                      variant: AppButtonVariant.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: AppSpacing.huge + AppSpacing.xs,
                    child: AppButton(
                      label: _isSigningOut ? 'Saindo...' : 'Sair',
                      onPressed: (_isSaving || _isSigningOut) ? null : _signOut,
                      variant: AppButtonVariant.danger,
                      trailingIcon: Icons.door_front_door_outlined,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
