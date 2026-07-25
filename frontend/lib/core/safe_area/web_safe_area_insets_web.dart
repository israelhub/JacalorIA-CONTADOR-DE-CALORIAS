import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

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
    px(style.paddingBottom),
  );
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
