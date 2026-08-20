import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import 'invite_link_service.dart';

/// Boots invite capture from the browser URL (web) or App/Universal Links (native).
class InviteLinkBootstrap {
  InviteLinkBootstrap._();

  static StreamSubscription<Uri>? _subscription;

  static Future<void> initialize() async {
    if (kIsWeb) {
      InviteLinkService.captureFromUri(Uri.base);
      return;
    }

    final appLinks = AppLinks();
    try {
      final initial = await appLinks.getInitialLink();
      if (initial != null) {
        InviteLinkService.captureFromUri(initial);
      }
    } catch (_) {}

    await _subscription?.cancel();
    _subscription = appLinks.uriLinkStream.listen(
      InviteLinkService.captureFromUri,
      onError: (_) {},
    );
  }
}
