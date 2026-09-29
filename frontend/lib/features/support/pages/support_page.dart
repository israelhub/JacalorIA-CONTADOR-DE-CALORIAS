import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../auth/helpers/auth_helpers.dart';
import '../../auth/service/auth_service.dart';
import '../services/support_service.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final _supportService = const SupportService();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();

  SupportSubjectType _subjectType = SupportSubjectType.bug;
  bool _isSending = false;

  bool get _isAuthenticated =>
      AuthService.globalToken != null && AuthService.globalToken!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (!_isAuthenticated) {
      final initialEmail = widget.initialEmail?.trim();
      if (initialEmail != null && initialEmail.isNotEmpty) {
        _emailController.text = initialEmail;
      } else {
        final userEmail = AuthService.globalUser?['email']?.toString().trim();
        if (userEmail != null && userEmail.isNotEmpty) {
          _emailController.text = userEmail;
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final description = _descriptionController.text.trim();
    if (description.length < 10) {
      AppToast.error(
        context,
        message: 'Descreva o problema com pelo menos 10 caracteres.',
      );
      return;
    }

    final email = _emailController.text.trim();
    if (!_isAuthenticated) {
      if (email.isEmpty) {
        AppToast.error(
          context,
          message: 'Informe seu e-mail para que possamos responder.',
        );
        return;
      }
      if (!AuthHelpers.isValidEmail(email)) {
        AppToast.error(context, message: 'Informe um e-mail válido.');
        return;
      }
    }

    setState(() => _isSending = true);

    try {
      await _supportService.sendMessage(
        subjectType: _subjectType,
        description: description,
        email: _isAuthenticated ? null : email,
      );

      if (!mounted) {
        return;
      }

      AppToast.success(
        context,
        message: 'Mensagem enviada! Obrigado pelo contato.',
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      AppToast.error(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Suporte',
          style: AppTextStyles.homeSectionTitle.copyWith(
            color: AppColors.brand900Variant,
          ),
        ),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Conte o que aconteceu ou compartilhe uma sugestão.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Assunto',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: SupportSubjectType.values.map((type) {
                  final isSelected = _subjectType == type;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: type == SupportSubjectType.bug
                            ? AppSpacing.sm
                            : 0,
                      ),
                      child: ChoiceChip(
                        selected: isSelected,
                        showCheckmark: false,
                        label: SizedBox(
                          width: double.infinity,
                          child: Text(
                            type.label,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        backgroundColor: AppColors.surfaceAlt,
                        selectedColor:
                            AppColors.action500.withValues(alpha: 0.2),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.action500
                              : AppColors.borderAlt,
                        ),
                        labelStyle: AppTextStyles.bodyMedium.copyWith(
                          color: isSelected
                              ? AppColors.action500
                              : AppColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        onSelected: _isSending
                            ? null
                            : (_) {
                                setState(() => _subjectType = type);
                              },
                      ),
                    ),
                  );
                }).toList(growable: false),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (!_isAuthenticated) ...[
                AppInputField(
                  label: 'E-mail',
                  hint: 'Digite seu e-mail',
                  controller: _emailController,
                  enabled: !_isSending,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              Text(
                'Descrição',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.foodReviewFieldBorder),
                  boxShadow: AppShadows.foodReviewField,
                ),
                child: TextField(
                  controller: _descriptionController,
                  enabled: !_isSending,
                  minLines: 6,
                  maxLines: 10,
                  textAlignVertical: TextAlignVertical.top,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Descreva o bug ou a sugestão com detalhes',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              SizedBox(
                height: AppSpacing.huge + AppSpacing.xs,
                child: AppButton(
                  label: _isSending ? 'Enviando…' : 'Enviar',
                  onPressed: _isSending ? null : _handleSend,
                  variant: AppButtonVariant.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
