import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/framed_avatar.dart';
import '../models/social_group_models.dart';

class SocialFriendRequestsDialog extends StatefulWidget {
  const SocialFriendRequestsDialog({
    super.key,
    required this.requests,
    required this.onAccept,
    required this.onReject,
  });

  final List<SocialFriendRequest> requests;
  final Future<void> Function(SocialFriendRequest request) onAccept;
  final Future<void> Function(SocialFriendRequest request) onReject;

  @override
  State<SocialFriendRequestsDialog> createState() => _SocialFriendRequestsDialogState();
}

class _SocialFriendRequestsDialogState extends State<SocialFriendRequestsDialog> {
  late final List<SocialFriendRequest> _requests;
  final Set<String> _loadingRequestIds = <String>{};

  @override
  void initState() {
    super.initState();
    _requests = List<SocialFriendRequest>.from(widget.requests);
  }

  Future<void> _handleAction({
    required SocialFriendRequest request,
    required Future<void> Function(SocialFriendRequest request) action,
  }) async {
    setState(() => _loadingRequestIds.add(request.id));
    try {
      await action(request);
      if (!mounted) return;
      setState(() {
        _loadingRequestIds.remove(request.id);
        _requests.removeWhere((item) => item.id == request.id);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingRequestIds.remove(request.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.performanceCardBorder, width: 2),
          boxShadow: AppShadows.performanceCard,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Solicitações de amizade',
                      style: AppTextStyles.missionsSectionTitle.copyWith(
                        color: AppColors.brand900Variant,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: _requests.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhuma solicitação pendente.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            for (var index = 0; index < _requests.length; index++) ...[
                              _FriendRequestItem(
                                request: _requests[index],
                                isLoading: _loadingRequestIds.contains(_requests[index].id),
                                onAccept: () => _handleAction(
                                  request: _requests[index],
                                  action: widget.onAccept,
                                ),
                                onReject: () => _handleAction(
                                  request: _requests[index],
                                  action: widget.onReject,
                                ),
                              ),
                              if (index < _requests.length - 1) ...[
                                const SizedBox(height: AppSpacing.md),
                                const Divider(color: AppColors.borderAlt, height: 1),
                                const SizedBox(height: AppSpacing.md),
                              ],
                            ],
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendRequestItem extends StatelessWidget {
  const _FriendRequestItem({
    required this.request,
    required this.isLoading,
    required this.onAccept,
    required this.onReject,
  });

  final SocialFriendRequest request;
  final bool isLoading;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FramedAvatar(
                size: 42,
                avatarUrl: request.requesterAvatarUrl,
                frameId: request.requesterAvatarFrameId,
                fallbackText: request.requesterName,
                backgroundColor: AppColors.surface,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.requesterName,
                      style: AppTextStyles.homeMealTitle.copyWith(
                        color: AppColors.brand900Variant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (isLoading)
            const LinearProgressIndicator(color: AppColors.action500)
          else
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Recusar',
                    variant: AppButtonVariant.outline,
                    onPressed: onReject,
                    textStyle: AppTextStyles.buttonMedium.copyWith(fontSize: 14),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: 'Aceitar',
                    onPressed: onAccept,
                    textStyle: AppTextStyles.buttonMedium.copyWith(fontSize: 14),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
