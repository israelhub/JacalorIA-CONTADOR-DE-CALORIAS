import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/notifications/meal_reminder_models.dart';
import '../../../core/notifications/meal_reminder_prefs.dart';
import '../../../core/notifications/meal_reminder_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_dashed_action_button.dart';
import '../../../shared/widgets/app_page_route.dart';
import '../../../shared/widgets/app_time_picker.dart';
import '../../../shared/widgets/app_toast.dart';
import 'meal_reminder_name_page.dart';

class MealRemindersPage extends StatefulWidget {
  const MealRemindersPage({super.key});

  @override
  State<MealRemindersPage> createState() => _MealRemindersPageState();
}

class _MealRemindersPageState extends State<MealRemindersPage> {
  MealReminderSettings _settings = MealReminderSettings.defaults();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackScreen('meal_reminders');
    _load();
  }

  Future<void> _load() async {
    final settings = await MealReminderPrefs.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _persist(
    MealReminderSettings next, {
    String? successMessage,
  }) async {
    setState(() {
      _settings = next;
      _saving = true;
    });

    try {
      await MealReminderService.instance.applySettings(next);
      if (!mounted) {
        return;
      }
      if (next.masterEnabled) {
        final enabled =
            await MealReminderService.instance.areNotificationsEnabled();
        if (!mounted) {
          return;
        }
        if (!enabled) {
          AppToast.error(
            context,
            message: kIsWeb
                ? 'Permita notificações neste site para receber os lembretes.'
                : 'Ative as notificações nas configurações do celular para receber os lembretes.',
          );
        } else {
          AppToast.success(
            context,
            message: successMessage ??
                (kIsWeb
                    ? 'Lembretes atualizados. Mantém a aba aberta para receber os avisos.'
                    : 'Lembretes atualizados.'),
          );
        }
      } else {
        AppToast.success(
          context,
          message: successMessage ?? 'Lembretes desativados.',
        );
      }
    } catch (_) {
      if (mounted) {
        AppToast.error(
          context,
          message: 'Não foi possível atualizar os lembretes.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickTime(MealReminderConfig current) async {
    final picked = await showAppTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: 'Horário — ${current.title}',
    );
    if (picked == null || !mounted) {
      return;
    }
    await _persist(
      _settings.withReminder(
        current.copyWith(hour: picked.hour, minute: picked.minute),
      ),
    );
  }

  Future<void> _editTitle(MealReminderConfig current) async {
    final result = await context.pushSlidePage<String>(
      MealReminderNamePage(config: current),
    );
    if (result == null || !mounted) {
      return;
    }
    final title = result.trim();
    if (title.isEmpty || title == current.title) {
      return;
    }
    await _persist(_settings.withReminder(current.copyWith(title: title)));
  }

  Future<void> _addReminder() async {
    if (!_settings.canAddMore) {
      AppToast.show(
        context,
        message: 'Você já atingiu o máximo de ${MealReminderSettings.maxReminders} lembretes.',
      );
      return;
    }

    final picked = await showAppTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 15, minute: 30),
      helpText: 'Horário do novo lembrete',
    );
    if (picked == null || !mounted) {
      return;
    }

    final created = MealReminderConfig.custom(
      hour: picked.hour,
      minute: picked.minute,
    );
    final next = _settings.tryAdd(created);
    if (next == null) {
      AppToast.show(
        context,
        message: 'Você já atingiu o máximo de ${MealReminderSettings.maxReminders} lembretes.',
      );
      return;
    }
    await _persist(next, successMessage: 'Lembrete adicionado.');
  }

  Future<void> _removeReminder(MealReminderConfig config) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Remover lembrete?',
            style: AppTextStyles.homeSectionTitle.copyWith(
              color: AppColors.brand900Variant,
            ),
          ),
          content: Text(
            'O aviso de "${config.title}" às ${config.timeLabel} será removido.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancelar',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Remover',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textError,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await _persist(
      _settings.withoutReminder(config.id),
      successMessage: 'Lembrete removido.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = _settings.reminders.length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Lembretes de refeição',
          style: AppTextStyles.homeSectionTitle.copyWith(
            color: AppColors.brand900Variant,
          ),
        ),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.action500),
              )
            : ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.lg,
                ),
                children: [
                  Text(
                    'Receba avisos perto do horário das suas refeições '
                    'para não esquecer de registrar. Até ${MealReminderSettings.maxReminders} lembretes.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (kIsWeb) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No navegador, os avisos funcionam com esta aba aberta '
                      '(limitação dos browsers). No app Android/iOS, disparam '
                      'mesmo com o app fechado.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  _MasterToggleCard(
                    enabled: _settings.masterEnabled,
                    busy: _saving,
                    onChanged: (value) {
                      _persist(_settings.copyWith(masterEnabled: value));
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Seus lembretes',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '$count/${MealReminderSettings.maxReminders}',
                        style: AppTextStyles.captionStrong.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final config in _settings.reminders) ...[
                    _MealReminderTile(
                      config: config,
                      masterEnabled: _settings.masterEnabled,
                      busy: _saving,
                      onEnabledChanged: (value) {
                        _persist(
                          _settings.withReminder(
                            config.copyWith(enabled: value),
                          ),
                        );
                      },
                      onTapTime: () => _pickTime(config),
                      onTapTitle: () => _editTitle(config),
                      onRemove: () => _removeReminder(config),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (_settings.canAddMore)
                    AppDashedActionButton(
                      label: 'Adicionar lembrete',
                      onTap: _saving ? null : _addReminder,
                      leading: const Icon(
                        Icons.add_rounded,
                        color: AppColors.action500,
                        size: 22,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        'Limite de ${MealReminderSettings.maxReminders} lembretes atingido. '
                        'Remova um para adicionar outro.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _MasterToggleCard extends StatelessWidget {
  const _MasterToggleCard({
    required this.enabled,
    required this.busy,
    required this.onChanged,
  });

  final bool enabled;
  final bool busy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderBrand),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lembretes ativos',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.brand900Variant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  enabled
                      ? 'Avisos diários ligados.'
                      : 'Nenhum lembrete será enviado.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.86,
            child: Switch(
              value: enabled,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeThumbColor: AppColors.surface,
              activeTrackColor: AppColors.action500,
              inactiveThumbColor: AppColors.textMuted,
              inactiveTrackColor: AppColors.surface,
              onChanged: busy ? null : onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealReminderTile extends StatelessWidget {
  const _MealReminderTile({
    required this.config,
    required this.masterEnabled,
    required this.busy,
    required this.onEnabledChanged,
    required this.onTapTime,
    required this.onTapTitle,
    required this.onRemove,
  });

  final MealReminderConfig config;
  final bool masterEnabled;
  final bool busy;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onTapTime;
  final VoidCallback onTapTitle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final interactive = masterEnabled && !busy;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.homeMealCardBorder),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: interactive ? onTapTitle : null,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            config.title,
                            style: AppTextStyles.homeMealTitle.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (interactive) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                InkWell(
                  onTap: interactive && config.enabled ? onTapTime : null,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: interactive && config.enabled
                              ? AppColors.action500
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          config.timeLabel,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: interactive && config.enabled
                                ? AppColors.brand900Variant
                                : AppColors.textTertiary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (interactive && config.enabled) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'alterar',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.action500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: busy ? null : onRemove,
            tooltip: 'Remover lembrete',
            icon: Icon(
              Icons.delete_outline_rounded,
              color: busy ? AppColors.textTertiary : AppColors.foodReviewDeleteIcon,
            ),
          ),
          Transform.scale(
            scale: 0.86,
            child: Switch(
              value: config.enabled,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeThumbColor: AppColors.surface,
              activeTrackColor: AppColors.action500,
              inactiveThumbColor: AppColors.textMuted,
              inactiveTrackColor: AppColors.surfaceAlt,
              onChanged: interactive ? onEnabledChanged : null,
            ),
          ),
        ],
      ),
    );
  }
}
