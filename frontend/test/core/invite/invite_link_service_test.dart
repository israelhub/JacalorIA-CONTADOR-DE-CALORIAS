import 'package:flutter_test/flutter_test.dart';

import 'package:jacaloria/core/invite/invite_link_service.dart';

void main() {
  tearDown(InviteLinkService.clear);

  test('captures friend invite from /friend?code=', () {
    InviteLinkService.captureFromUri(
      Uri.parse('https://jacaloria.online/friend?code=abc123'),
    );

    final invite = InviteLinkService.take();
    expect(invite, isNotNull);
    expect(invite!.kind, InviteLinkKind.friend);
    expect(invite.code, 'ABC123');
    expect(InviteLinkService.hasPending, isFalse);
  });

  test('captures group invite from /group?code=', () {
    InviteLinkService.captureFromUri(
      Uri.parse('https://jacaloria.online/group?code=xyz789'),
    );

    final invite = InviteLinkService.pending;
    expect(invite?.kind, InviteLinkKind.group);
    expect(invite?.code, 'XYZ789');
  });

  test('captures invite from query invite= param', () {
    InviteLinkService.captureFromUri(
      Uri.parse('https://jacaloria.online/?invite=group&code=code01'),
    );

    expect(InviteLinkService.pending?.kind, InviteLinkKind.group);
    expect(InviteLinkService.pending?.code, 'CODE01');
  });

  test('captures invite from jacaloria:// custom scheme', () {
    InviteLinkService.captureFromUri(
      Uri.parse('jacaloria://friend?code=abc123'),
    );

    final invite = InviteLinkService.take();
    expect(invite?.kind, InviteLinkKind.friend);
    expect(invite?.code, 'ABC123');
  });

  test('bumps revision when a new invite is captured', () {
    final before = InviteLinkService.revision.value;
    InviteLinkService.captureFromUri(
      Uri.parse('https://jacaloria.online/friend?code=rev001'),
    );
    expect(InviteLinkService.revision.value, before + 1);
  });

  test('ignores urls without invite context', () {
    InviteLinkService.captureFromUri(
      Uri.parse('https://jacaloria.online/?code=ABC123'),
    );
    expect(InviteLinkService.hasPending, isFalse);
  });
}
