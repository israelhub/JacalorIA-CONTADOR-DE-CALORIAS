import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/services/supabase_storage_service.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_confirm_modal.dart';
import '../../../../shared/widgets/app_date_picker.dart';
import '../../../../shared/widgets/app_input.dart';
import '../../../../shared/widgets/app_select_input_field.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/measurement_input_field.dart';
import '../../auth/service/auth_service.dart';
import '../helpers/profile_date_helpers.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key, required this.initialProfile});

  final Map<String, dynamic> initialProfile;

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _authService = AuthService();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _objectiveController = TextEditingController();
  final _activityController = TextEditingController();

  String? _selectedSex;
  String? _selectedObjective;
  String? _selectedActivityLevel;
  String? _avatarUrl;
  String _selectedWeightUnit = 'kg';
  String _selectedHeightUnit = 'cm';
  bool _isSaving = false;
  bool _isHandlingExit = false;

  String _initialName = '';
  String _initialBirthDate = '';
  String _initialWeight = '';
  String _initialHeight = '';
  String? _initialSex;
  String? _initialObjective;
  String? _initialActivityLevel;
  String? _initialAvatarUrl;
  String _initialWeightUnit = 'kg';
  String _initialHeightUnit = 'cm';

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _objectiveController.dispose();
    _activityController.dispose();
    super.dispose();
  }

  void _hydrateProfile() {
    final profile = widget.initialProfile;

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
    _selectedObjective = _normalizeObjective(profile['objective'] as String?);
    _selectedActivityLevel =
        (profile['activityLevel'] as String?) ??
        (profile['activity_level'] as String?);

    _objectiveController.text = _objectiveLabels[_selectedObjective] ?? '';
    _activityController.text = _activityLabels[_selectedActivityLevel] ?? '';
    _captureInitialSnapshot();
  }

  void _captureInitialSnapshot() {
    _initialName = _nameController.text;
    _initialBirthDate = _birthDateController.text;
    _initialWeight = _weightController.text;
    _initialHeight = _heightController.text;
    _initialSex = _selectedSex;
    _initialObjective = _selectedObjective;
    _initialActivityLevel = _selectedActivityLevel;
    _initialAvatarUrl = _avatarUrl;
    _initialWeightUnit = _selectedWeightUnit;
    _initialHeightUnit = _selectedHeightUnit;
  }

  bool get _hasUnsavedChanges {
    return _nameController.text != _initialName ||
        _birthDateController.text != _initialBirthDate ||
        _weightController.text != _initialWeight ||
        _heightController.text != _initialHeight ||
        _selectedSex != _initialSex ||
        _selectedObjective != _initialObjective ||
        _selectedActivityLevel != _initialActivityLevel ||
        _avatarUrl != _initialAvatarUrl ||
        _selectedWeightUnit != _initialWeightUnit ||
        _selectedHeightUnit != _initialHeightUnit;
  }

  Future<void> _handleExitAttempt() async {
    if (_isHandlingExit || _isSaving) {
      return;
    }

    if (!_hasUnsavedChanges) {
      Navigator.of(context).pop(false);
      return;
    }

    _isHandlingExit = true;
    try {
      final shouldSave = await AppConfirmModal.show(
        context,
        title: 'Deseja salvar as alterações?',
        message:
            'Você editou dados do perfil. Escolha se deseja salvar antes de sair.',
        confirmLabel: 'Salvar',
        cancelLabel: 'Não salvar',
        barrierDismissible: false,
      );

      if (!mounted) {
        return;
      }

      if (shouldSave) {
        await _saveProfile();
      } else {
        Navigator.of(context).pop(false);
      }
    } finally {
      _isHandlingExit = false;
    }
  }

  String _formatNumber(num value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  String? _normalizeObjective(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    const map = <String, String>{
      'loseweight': 'loseWeight',
      'lose_weight': 'loseWeight',
      'gainmass': 'gainMass',
      'gain_mass': 'gainMass',
      'gainmuscle': 'gainMass',
      'gain_muscle': 'gainMass',
      'maintainweight': 'maintainWeight',
      'maintain_weight': 'maintainWeight',
      'maintenance': 'maintainWeight',
    };

    final normalizedKey = raw.toLowerCase().replaceAll(RegExp(r'[^a-z_]'), '');
    return map[normalizedKey] ?? raw;
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initialDate = DateTime(now.year - 18, now.month, now.day);

    final selectedDate = await showAppDatePicker(
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
          AppToast.error(
            context,
            message: 'Falha ao enviar foto de perfil.',
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

    setState(() {
      _isSaving = true;
    });

    try {
      await _authService.updateProfile(data);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, message: 'Erro ao salvar perfil: $e');
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
    final avatarUrl = _avatarUrl;
    final initial = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()[0].toUpperCase()
        : 'P';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handleExitAttempt();
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          surfaceTintColor: AppColors.surface,
          title: Text(
            'Editar dados pessoais',
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.brand900Variant,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _isSaving ? null : _pickAvatar,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.surfaceAlt,
                          backgroundImage: avatarUrl?.startsWith('http') == true
                              ? NetworkImage(avatarUrl!)
                              : null,
                          child: avatarUrl?.startsWith('http') == true
                              ? null
                              : Text(
                                  initial,
                                  style: AppTextStyles.headingSmall.copyWith(
                                    color: AppColors.brand900Variant,
                                  ),
                                ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.action500,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              border: Border.all(
                                color: AppColors.surface,
                                width: 2,
                              ),
                            ),
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 14,
                              color: AppColors.surface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
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
                    'profile-edit-weight-unit-selector',
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
                    'profile-edit-height-unit-selector',
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
                  fieldKey: const ValueKey('profile-edit-activity-field'),
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
                  fieldKey: const ValueKey('profile-edit-sex-field'),
                  label: 'Sexo',
                  hint: 'Selecione seu sexo',
                  selectedValue: _selectedSex ?? '',
                  options: _sexOptions,
                  onSelected: (value) {
                    setState(() {
                      _selectedSex = value;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSelectInputField(
                  fieldKey: const ValueKey('profile-edit-objective-field'),
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
                    label: _isSaving ? 'Salvando...' : 'Salvar alterações',
                    onPressed: _isSaving ? null : _saveProfile,
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
