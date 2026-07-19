import 'package:flutter/widgets.dart';

import 'web_safe_area_insets_stub.dart'
    if (dart.library.js_interop) 'web_safe_area_insets_web.dart' as impl;

/// Reads CSS `env(safe-area-inset-*)` from the probe in `web/index.html`.
///
/// On non-web platforms this always returns [EdgeInsets.zero].
EdgeInsets readWebCssSafeAreaInsets() => impl.readWebCssSafeAreaInsets();
