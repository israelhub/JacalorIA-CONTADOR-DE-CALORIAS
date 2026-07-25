import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Hard cap for the home-indicator / gesture inset (CSS px ≈ logical px on web).
const double kMaxWebBottomSafeAreaInset = 34;

EdgeInsets readWebCssSafeAreaInsets() {
  final probe = web.document.getElementById('flt-safe-area-probe');
  if (probe == null) {
    return EdgeInsets.zero;
  }

  final style = web.window.getComputedStyle(probe);

  double px(String value) {
    if (value.isEmpty || value == 'auto') return 0;
    return double.tryParse(value.replaceAll('px', '').trim()) ?? 0;
  }

  // iOS PWAs sometimes over-report inset-bottom (browser chrome, bugs).
  // The physical home indicator / gesture bar stays within ~34px.
  final bottom = math.min(px(style.paddingBottom), kMaxWebBottomSafeAreaInset);

  return EdgeInsets.fromLTRB(
    px(style.paddingLeft),
    px(style.paddingTop),
    px(style.paddingRight),
    bottom,
  );
}

StreamSubscription<void> listenWebSafeAreaChanges(void Function() onChanged) {
  final controller = StreamController<void>.broadcast();

  void emit(web.Event _) {
    if (!controller.isClosed) controller.add(null);
  }

  final jsListener = emit.toJS;
  web.window.addEventListener('jacaloria-safe-area', jsListener);
  web.window.addEventListener('resize', jsListener);

  controller.onCancel = () {
    web.window.removeEventListener('jacaloria-safe-area', jsListener);
    web.window.removeEventListener('resize', jsListener);
    if (!controller.isClosed) unawaited(controller.close());
  };

  return controller.stream.listen((_) => onChanged());
}
