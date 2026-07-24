import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/notifications/in_app_message_models.dart';
import '../../../core/notifications/in_app_message_store.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_toast.dart';

class InAppMessagesPage extends StatefulWidget {
  const InAppMessagesPage({super.key, this.store});

  final InAppMessageStore? store;

  @override
  State<InAppMessagesPage> createState() => _InAppMessagesPageState();
}

class _InAppMessagesPageState extends State<InAppMessagesPage> {
  InAppMessageStore get _store => widget.store ?? InAppMessageStore.instance;

  var _loading = true;
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackScreen('in_app_messages');
    _store.addListener(_onStoreChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _bootstrap() async {
    await _store.ensureLoaded();
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);
  }

  Future<void> _openMessage(InAppMessage message) async {
    setState(() {
      _expandedId = _expandedId == message.id ? null : message.id;
    });
    if (message.isUnread) {
      await _store.markRead(message.id);
    }
  }

  Future<void> _deleteMessage(InAppMessage message) async {
    await _store.delete(message.id);
    if (!mounted) {
      return;
    }
    if (_expandedId == message.id) {
      setState(() => _expandedId = null);
    }
    AppToast.success(context, message: 'Mensagem excluída.');
  }

  String _formatWhen(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final messages = _store.messages;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xxl,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  IconButton(
                    key: const ValueKey('in-app-messages-back'),
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.brand900Variant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Expanded(
                    child: AppPageHeader(
                      title: 'Notificações',
                      icon: Icons.notifications_outlined,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xxl),
                        child: Text(
                          'Nenhuma mensagem por enquanto.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.xxxl,
                      ),
                      itemCount: messages.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final expanded = _expandedId == message.id;
                        return _MessageCard(
                          message: message,
                          expanded: expanded,
                          whenLabel: _formatWhen(message.createdAt),
                          onTap: () => _openMessage(message),
                          onDelete: () => _deleteMessage(message),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.message,
    required this.expanded,
    required this.whenLabel,
    required this.onTap,
    required this.onDelete,
  });

  final InAppMessage message;
  final bool expanded;
  final String whenLabel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final unread = message.isUnread;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        key: ValueKey('in-app-message-${message.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: unread ? AppColors.action500 : AppColors.borderAlt,
              width: unread ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (unread) ...[
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 6, right: AppSpacing.sm),
                      decoration: const BoxDecoration(
                        color: AppColors.action500,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                  Expanded(
                    child: Text(
                      message.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.brand900Variant,
                        fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    key: ValueKey('in-app-message-delete-${message.id}'),
                    tooltip: 'Excluir mensagem',
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                whenLabel,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (expanded || message.body.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message.body,
                  maxLines: expanded ? null : 2,
                  overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
