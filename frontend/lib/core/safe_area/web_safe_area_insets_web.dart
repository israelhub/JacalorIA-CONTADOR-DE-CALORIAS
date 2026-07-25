import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Max CSS px for the home indicator / gesture inset on web.
///
/// iOS "Add to Home Screen" PWAs have been seen reporting
/// `safe-area-inset-bottom` far above the real home indicator (~34), which
/// lifts the bottom nav and leaves a tall empty band under the icons.
const double kMaxWebBottomSafeAreaInset = 34;

EdgeInsets readWebCssSafeAreaInsets() {
  final probe = web.document.getElementById('flt-safe-area-probe');
  if (probe == null) {
    return EdgeInsets.zero;
  }

  final style = web.window.getComputedStyle(probe);

  double px(String value) {
    if (value.isEmpty || value == 'auto') {
      return 0;
    }
    return double.tryParse(value.replaceAll('px', '').trim()) ?? 0;
  }

  return EdgeInsets.fromLTRB(
    px(style.paddingLeft),
    px(style.paddingTop),
    px(style.paddingRight),
    _effectiveBottomInset(px(style.paddingBottom)),
  );
}

/// Home-indicator inset to apply inside the Flutter view.
///
/// Caps absurd CSS values and subtracts any bottom gap the browser already
/// excluded from the visual viewport, so the bottom nav sits flush above the
/// system gesture / home indicator instead of floating too high.
double _effectiveBottomInset(double cssBottom) {
  final capped = math.min(cssBottom, kMaxWebBottomSafeAreaInset);
  if (capped <= 0) {
    return 0;
  }

  final visualViewport = web.window.visualViewport;
  if (visualViewport == null) {
    return capped;
  }

  final innerHeight = web.window.innerHeight.toDouble();
  final alreadyExcluded = math.max(
    0.0,
    innerHeight - visualViewport.height - visualViewport.offsetTop,
  );
  return math.max(0.0, capped - alreadyExcluded);
}

StreamSubscription<void> listenWebSafeAreaChanges(void Function() onChanged) {
  final controller = StreamController<void>.broadcast();

  void emit(web.Event _) {
    if (!controller.isClosed) {
      controller.add(null);
    }
  }

  final jsListener = emit.toJS;
  web.window.addEventListener('jacaloria-safe-area', jsListener);
  web.window.addEventListener('resize', jsListener);
  final visualViewport = web.window.visualViewport;
  visualViewport?.addEventListener('resize', jsListener);

  controller.onCancel = () {
    web.window.removeEventListener('jacaloria-safe-area', jsListener);
    web.window.removeEventListener('resize', jsListener);
    visualViewport?.removeEventListener('resize', jsListener);
    if (!controller.isClosed) {
      unawaited(controller.close());
    }
  };

  return controller.stream.listen((_) => onChanged());
}
