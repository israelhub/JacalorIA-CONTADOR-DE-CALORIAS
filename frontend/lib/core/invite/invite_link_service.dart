import 'package:flutter/foundation.dart';

enum InviteLinkKind { friend, group }

class PendingInvite {
  const PendingInvite({required this.kind, required this.code});

  final InviteLinkKind kind;
  final String code;
}

/// Captures friendship/group invite deep links from web URL or native App Links.
///
/// Supported formats:
/// - `/friend?code=ABC123`
/// - `/group?code=ABC123`
/// - `/?invite=friend&code=ABC123`
/// - `/?invite=group&code=ABC123`
/// - `jacaloria://friend?code=ABC123`
/// - `jacaloria://group?code=ABC123`
class InviteLinkService {
  InviteLinkService._();

  static PendingInvite? _pending;
  static int _revision = 0;

  /// Bumps when a new invite is captured so UI can react to warm-start links.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static PendingInvite? get pending => _pending;

  static bool get hasPending => _pending != null;

  static void captureFromUri(Uri uri) {
    final code = _readCode(uri);
    if (code == null) return;

    final kind = _readKind(uri);
    if (kind == null) return;

    _pending = PendingInvite(kind: kind, code: code);
    _revision++;
    revision.value = _revision;
  }

  static PendingInvite? take() {
    final invite = _pending;
    _pending = null;
    return invite;
  }

  static void clear() {
    _pending = null;
  }

  static String? _readCode(Uri uri) {
    final fromQuery = uri.queryParameters['code']?.trim().toUpperCase();
    if (fromQuery != null && fromQuery.isNotEmpty) {
      return fromQuery;
    }

    final segments = uri.pathSegments
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
    if (segments.length >= 2) {
      final maybeKind = segments[segments.length - 2].toLowerCase();
      final maybeCode = segments.last.trim().toUpperCase();
      if ((maybeKind == 'friend' || maybeKind == 'group') &&
          maybeCode.isNotEmpty) {
        return maybeCode;
      }
    }

    return null;
  }

  static InviteLinkKind? _readKind(Uri uri) {
    final inviteParam = uri.queryParameters['invite']?.trim().toLowerCase();
    if (inviteParam == 'friend') return InviteLinkKind.friend;
    if (inviteParam == 'group') return InviteLinkKind.group;

    final host = uri.host.trim().toLowerCase();
    if (host == 'friend') return InviteLinkKind.friend;
    if (host == 'group') return InviteLinkKind.group;

    final path = '/${uri.pathSegments.where((s) => s.trim().isNotEmpty).join('/')}'.toLowerCase();
    if (path == '/friend' || path.endsWith('/friend')) {
      return InviteLinkKind.friend;
    }
    if (path == '/group' || path.endsWith('/group')) {
      return InviteLinkKind.group;
    }

    return null;
  }
}
