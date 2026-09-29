import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../widgets/social_profile_invite_card.dart';

class SocialAddFriendPage extends StatelessWidget {
  const SocialAddFriendPage({
    super.key,
    required this.userName,
    required this.userAvatarUrl,
    required this.userAvatarFrameId,
    required this.qrPayload,
    required this.onCopyId,
    required this.onSearchUser,
    required this.onScanQr,
    required this.onShareLink,
  });

  final String userName;
  final String? userAvatarUrl;
  final String? userAvatarFrameId;
  final String qrPayload;
  final VoidCallback onCopyId;
  final VoidCallback onSearchUser;
  final VoidCallback onScanQr;
  final VoidCallback onShareLink;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.brand900Variant,
        title: Text(
          'Adicionar amigo',
          style: AppTextStyles.missionsSectionTitle.copyWith(
            color: AppColors.brand900Variant,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SocialProfileInviteCard(
                name: userName,
                avatarUrl: userAvatarUrl,
                avatarFrameId: userAvatarFrameId,
                onCopyId: onCopyId,
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text(
                  'Escanear para adicionar aos amigos',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.captionStrong.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: QrImageView(
                  data: qrPayload,
                  size: 240,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Buscar usuário',
                      variant: AppButtonVariant.outline,
                      leadingIcon: Icons.search_rounded,
                      onPressed: onSearchUser,
                      textStyle: AppTextStyles.buttonMedium.copyWith(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: 'Escanear QR',
                      variant: AppButtonVariant.outline,
                      leadingIcon: Icons.qr_code_scanner_rounded,
                      onPressed: onScanQr,
                      textStyle: AppTextStyles.buttonMedium.copyWith(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Compartilhar link de amizade',
                variant: AppButtonVariant.primary,
                leadingIcon: Icons.share_rounded,
                onPressed: onShareLink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
