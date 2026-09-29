import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/framed_avatar.dart';
import '../models/social_group_models.dart';

class SocialFriendRequestsPage extends StatefulWidget {
  const SocialFriendRequestsPage({
    super.key,
    required this.requests,
    required this.onAccept,
    required this.onReject,
  });

  final List<SocialFriendRequest> requests;
  final Future<void> Function(SocialFriendRequest request) onAccept;
  final Future<void> Function(SocialFriendRequest request) onReject;

  @override
  State<SocialFriendRequestsPage> createState() => _SocialFriendRequestsPageState();
}

class _SocialFriendRequestsPageState extends State<SocialFriendRequestsPage> {
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
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.brand900Variant,
        title: Text(
          'Solicitações de amizade',
          style: AppTextStyles.missionsSectionTitle.copyWith(
            color: AppColors.brand900Variant,
          ),
        ),
      ),
      body: SafeArea(
        child: _requests.isEmpty
            ? Center(
                child: Text(
                  'Nenhuma solicitação pendente.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: _requests.length,
                separatorBuilder: (_, __) => const Divider(
                  color: AppColors.borderAlt,
                  height: AppSpacing.lg * 2,
                ),
                itemBuilder: (context, index) {
                  final request = _requests[index];
                  return _FriendRequestItem(
                    request: request,
                    isLoading: _loadingRequestIds.contains(request.id),
                    onAccept: () => _handleAction(
                      request: request,
                      action: widget.onAccept,
                    ),
                    onReject: () => _handleAction(
                      request: request,
                      action: widget.onReject,
                    ),
                  );
                },
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
    return Column(
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
              child: Text(
                request.requesterName,
                style: AppTextStyles.homeMealTitle.copyWith(
                  color: AppColors.brand900Variant,
                ),
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
    );
  }
}
