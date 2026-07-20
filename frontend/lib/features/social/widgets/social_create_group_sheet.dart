import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/app_toast.dart';
import '../helpers/social_group_helpers.dart';
import '../models/social_group_models.dart';
import '../services/social_service.dart';

class SocialCreateGroupSheet extends StatefulWidget {
  const SocialCreateGroupSheet({
    super.key,
    SocialService? service,
    this.existingGroup,
    this.onDeleteRequested,
  }) : _service = service ?? const SocialService();

  final SocialService _service;
  final SocialGroupSummary? existingGroup;
  final Future<void> Function()? onDeleteRequested;

  @override
  State<SocialCreateGroupSheet> createState() => _SocialCreateGroupSheetState();
}

class _SocialCreateGroupSheetState extends State<SocialCreateGroupSheet> {
  static const _icons = <_SocialIconOption>[
    _SocialIconOption('salad', Icons.eco_rounded),
    _SocialIconOption('muscle', Icons.fitness_center_rounded),
    _SocialIconOption('fire', Icons.local_fire_department_rounded),
    _SocialIconOption('trophy', Icons.emoji_events_rounded),
    _SocialIconOption('rocket', Icons.rocket_launch_rounded),
    _SocialIconOption('apple', Icons.restaurant_rounded),
    _SocialIconOption('avocado', Icons.favorite_rounded),
  ];

  static const _competitionTypes = <_CompetitionTypeOption>[
    _CompetitionTypeOption('offensive', 'Sequência'),
    _CompetitionTypeOption('daily_goal', 'Meta diária'),
    _CompetitionTypeOption('goal_average', 'Média de meta'),
    _CompetitionTypeOption('xp', 'XP'),
    _CompetitionTypeOption('group_streak', 'Sequência dos amigos'),
  ];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedIconKey = 'salad';
  String _selectedCompetitionType = 'offensive';
  int _selectedDurationDays = 7;
  bool _isPublicGroup = false;
  bool _isSaving = false;

  bool get _isEditing => widget.existingGroup != null;

  static const List<int> _durationOptions = <int>[7, 14, 21, 30, 0];
  static const double _sectionGap = AppSpacing.lg;

  List<int> get _visibleDurationOptions {
    if (_selectedCompetitionType == 'group_streak') {
      return const <int>[0];
    }
    return _durationOptions.where((value) => value > 0).toList(growable: false);
  }

  String get _competitionDescription {
    return switch (_selectedCompetitionType) {
      'offensive' => 'Vence quem mantiver a maior sequência ativa no desafio.',
      'daily_goal' => 'Ganha quem bater mais vezes a própria meta diária.',
      'goal_average' =>
        'Ganha quem tiver a média de calorias dos dias registrados mais próxima da própria meta.',
      'xp' => 'Pontua as ações saudáveis para ranquear evolução no grupo.',
      'group_streak' => 'A sequência só cresce quando todos do grupo permanecem ativos.',
      _ => 'Vence quem mantiver a maior sequência ativa no desafio.',
    };
  }

  @override
  void initState() {
    super.initState();

    final group = widget.existingGroup;
    if (group != null) {
      _nameController.text = group.name;
      _descriptionController.text = group.description;
      _selectedIconKey = group.iconKey;
      _selectedCompetitionType = group.competitionType;
      _selectedDurationDays = group.durationDays;
      _isPublicGroup = group.isPublic;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty && !_isSaving;

  Future<void> _submit() async {
    if (!_canSubmit) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final result = _isEditing
          ? await widget._service.updateGroup(
              groupId: widget.existingGroup!.id,
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              competitionType: _selectedCompetitionType,
              iconKey: _selectedIconKey,
              durationDays: _selectedDurationDays,
              isPublic: _isPublicGroup,
            )
          : await widget._service.createGroup(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              competitionType: _selectedCompetitionType,
              iconKey: _selectedIconKey,
              durationDays: _selectedDurationDays,
              isPublic: _isPublicGroup,
            );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop<SocialGroupDetail>(result);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      AppToast.error(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.xs,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEditing ? 'Editar grupo' : 'Novo grupo',
                        style: AppTextStyles.missionsSectionTitle.copyWith(
                          color: AppColors.brand900Variant,
                        ),
                      ),
                    ),
                    _PressableScale(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(
                          Icons.close_rounded,
                          size: 22,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Ícone',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.brand900Variant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final option in _icons)
                      _IconPickerOption(
                        icon: option.icon,
                        selected: option.key == _selectedIconKey,
                        onTap: () {
                          setState(() {
                            _selectedIconKey = option.key;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppInputField(
                  label: 'Nome do grupo',
                  hint: 'Ex: Família Saudável',
                  controller: _nameController,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.md),
                AppInputField(
                  label: 'Descrição (opcional)',
                  hint: 'Sobre o grupo',
                  controller: _descriptionController,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Tempo do desafio',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.brand900Variant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var index = 0; index < _visibleDurationOptions.length; index++) ...[
                        if (index > 0) const SizedBox(width: AppSpacing.sm),
                        _DurationChip(
                          value: _visibleDurationOptions[index],
                          label: socialDurationLabel(_visibleDurationOptions[index]),
                          selected: _visibleDurationOptions[index] == _selectedDurationDays,
                          onTap: () {
                            setState(() {
                              _selectedDurationDays = _visibleDurationOptions[index];
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: _sectionGap),
                Text(
                  'Tipo de competição',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.brand900Variant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var index = 0; index < _competitionTypes.length; index++) ...[
                        if (index > 0) const SizedBox(width: AppSpacing.sm),
                        _CompetitionTypeChip(
                          label: _competitionTypes[index].label,
                          selected:
                              _competitionTypes[index].key == _selectedCompetitionType,
                          onTap: () {
                            setState(() {
                              _selectedCompetitionType = _competitionTypes[index].key;
                              if (_selectedCompetitionType == 'group_streak') {
                                _selectedDurationDays = 0;
                              } else if (_selectedDurationDays == 0) {
                                _selectedDurationDays = 7;
                              }
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _competitionDescription,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: _sectionGap),
                Text(
                  'Grupo público',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.brand900Variant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Transform.scale(
                      scale: 0.86,
                      child: Switch(
                        value: _isPublicGroup,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        activeThumbColor: AppColors.surface,
                        activeTrackColor: AppColors.action500,
                        inactiveThumbColor: AppColors.textMuted,
                        inactiveTrackColor: AppColors.surfaceAlt,
                        onChanged: (value) {
                          setState(() {
                            _isPublicGroup = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _isPublicGroup
                            ? 'Visível na lista pública para qualquer usuário entrar.'
                            : 'Somente por convite/código.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 48,
                  child: Opacity(
                    opacity: _canSubmit ? 1 : 0.5,
                    child: AppButton(
                      label: _isSaving
                          ? (_isEditing ? 'Salvando...' : 'Criando...')
                          : (_isEditing ? 'Salvar alterações' : 'Criar grupo'),
                      onPressed: _canSubmit ? _submit : null,
                      variant: AppButtonVariant.primary,
                    ),
                  ),
                ),
                if (_isEditing && widget.onDeleteRequested != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: AppButton(
                      label: 'Excluir grupo',
                      variant: AppButtonVariant.danger,
                      trailingIcon: Icons.delete_outline_rounded,
                      onPressed: _isSaving
                          ? null
                          : () async {
                              Navigator.of(context).pop();
                              await widget.onDeleteRequested!.call();
                            },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialIconOption {
  const _SocialIconOption(this.key, this.icon);

  final String key;
  final IconData icon;
}

class _CompetitionTypeOption {
  const _CompetitionTypeOption(this.key, this.label);

  final String key;
  final String label;
}

class _IconPickerOption extends StatelessWidget {
  const _IconPickerOption({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: selected ? AppColors.action500 : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.action500 : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          size: 22,
          color: selected ? AppColors.surface : AppColors.textMuted,
        ),
      ),
    );
  }
}

class _CompetitionTypeChip extends StatelessWidget {
  const _CompetitionTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.action500 : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.captionStrong.copyWith(
            color: selected ? AppColors.surface : AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.value,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final int value;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        key: ValueKey('social-duration-$value'),
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.action500 : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.captionStrong.copyWith(
            color: selected ? AppColors.surface : AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PressableScale extends StatefulWidget {
  const _PressableScale({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _isPressed = false;
  bool _isHovered = false;

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }
    setState(() {
      _isPressed = value;
    });
  }

  void _setHovered(bool value) {
    if (_isHovered == value) {
      return;
    }
    setState(() {
      _isHovered = value;
    });
  }

  Future<void> _handleTap() async {
    _setPressed(true);
    widget.onTap();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (!mounted) {
      return;
    }
    _setPressed(false);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) {},
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : (_isHovered ? 1.02 : 1),
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: _isHovered ? 0.92 : 1,
            duration: const Duration(milliseconds: 120),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
