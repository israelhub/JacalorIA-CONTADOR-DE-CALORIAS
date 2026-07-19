import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'web_safe_area_insets.dart';

/// Merges CSS safe-area insets into [MediaQuery] on Flutter Web.
///
/// iOS Safari and Android Chrome often leave Flutter's [MediaQuery.viewPadding]
/// at zero even when the system home indicator / gesture bar overlaps the UI.
/// Reading `env(safe-area-inset-*)` from the HTML probe fixes that.
class WebSafeAreaMediaQuery extends StatelessWidget {
  const WebSafeAreaMediaQuery({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return child;
    }

    final cssInsets = readWebCssSafeAreaInsets();
    if (cssInsets == EdgeInsets.zero) {
      return child;
    }

    final data = MediaQuery.of(context);
    final nextPadding = EdgeInsets.only(
      left: math.max(data.padding.left, cssInsets.left),
      top: math.max(data.padding.top, cssInsets.top),
      right: math.max(data.padding.right, cssInsets.right),
      bottom: math.max(data.padding.bottom, cssInsets.bottom),
    );
    final nextViewPadding = EdgeInsets.only(
      left: math.max(data.viewPadding.left, cssInsets.left),
      top: math.max(data.viewPadding.top, cssInsets.top),
      right: math.max(data.viewPadding.right, cssInsets.right),
      bottom: math.max(data.viewPadding.bottom, cssInsets.bottom),
    );

    if (nextPadding == data.padding && nextViewPadding == data.viewPadding) {
      return child;
    }

    return MediaQuery(
      data: data.copyWith(
        padding: nextPadding,
        viewPadding: nextViewPadding,
      ),
      child: child,
    );
  }
}
