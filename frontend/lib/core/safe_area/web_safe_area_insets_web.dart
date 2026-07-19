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
