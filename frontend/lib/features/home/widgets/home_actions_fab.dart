import 'package:flutter/material.dart';

import '../../../core/notifications/in_app_message_store.dart';
import '../../../shared/widgets/app_expandable_fab.dart';
import '../../../shared/widgets/app_page_route.dart';
import '../../notifications/pages/in_app_messages_page.dart';
import 'home_weight_quick_edit_button.dart';

/// Expandable home FAB: peso + notificações (mesmo padrão do perfil).
class HomeActionsFab extends StatefulWidget {
  const HomeActionsFab({
    super.key,
    required this.userProfile,
    required this.onWeightUpdated,
    this.messageStore,
  });

  final Map<String, dynamic>? userProfile;
  final ValueChanged<Map<String, dynamic>> onWeightUpdated;
  final InAppMessageStore? messageStore;

  @override
  State<HomeActionsFab> createState() => _HomeActionsFabState();
}

class _HomeActionsFabState extends State<HomeActionsFab> {
  final _weightController = HomeWeightQuickEditController();

  InAppMessageStore get _store =>
      widget.messageStore ?? InAppMessageStore.instance;

  @override
  void initState() {
    super.initState();
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
    await _store.syncDueMealReminders();
  }

  void _openNotifications() {
    context.pushSlidePage(InAppMessagesPage(store: _store));
  }

  @override
  Widget build(BuildContext context) {
    final unread = _store.unreadCount;

    return Stack(
      alignment: Alignment.bottomRight,
      clipBehavior: Clip.none,
      children: [
        // Host invisível do editor de peso (abre via controller).
        HomeWeightQuickEditButton(
          userProfile: widget.userProfile,
          onWeightUpdated: widget.onWeightUpdated,
          controller: _weightController,
          showTrigger: false,
        ),
        AppExpandableFab(
          key: const ValueKey('home-actions-fab'),
          menuWidth: 248,
          closedIcon: Icons.add_rounded,
          openIcon: Icons.close_rounded,
          closedSemanticLabel: 'Abrir ações da home',
          openSemanticLabel: 'Fechar ações da home',
          actions: [
            AppExpandableFabAction(
              key: const ValueKey('home-fab-notifications'),
              label: 'Notificações',
              icon: Icons.notifications_outlined,
              badgeCount: unread > 0 ? unread : null,
              semanticLabel: unread > 0
                  ? 'Notificações, $unread não lidas'
                  : 'Notificações',
              onPressed: _openNotifications,
            ),
            AppExpandableFabAction(
              key: const ValueKey('home-fab-weight'),
              label: 'Peso',
              icon: Icons.monitor_weight_outlined,
              onPressed: _weightController.open,
            ),
          ],
        ),
      ],
    );
  }
}
