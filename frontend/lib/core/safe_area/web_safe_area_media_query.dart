import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'web_safe_area_insets.dart';

/// Merges CSS safe-area insets into [MediaQuery] on Flutter Web.
///
/// iOS Safari and Android Chrome often leave Flutter's [MediaQuery.viewPadding]
/// at zero even when the system home indicator / gesture bar overlaps the UI.
/// Reading `env(safe-area-inset-*)` from the HTML probe fixes that.
///
/// On iOS home-screen PWAs, Flutter also strips `viewport-fit=cover` and
/// restores it asynchronously — this widget re-reads insets when that happens.
class WebSafeAreaMediaQuery extends StatefulWidget {
  const WebSafeAreaMediaQuery({super.key, required this.child});

  final Widget child;

  @override
  State<WebSafeAreaMediaQuery> createState() => _WebSafeAreaMediaQueryState();
}

class _WebSafeAreaMediaQueryState extends State<WebSafeAreaMediaQuery>
    with WidgetsBindingObserver {
  EdgeInsets _cssInsets = EdgeInsets.zero;
  StreamSubscription<void>? _safeAreaSubscription;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      return;
    }
    WidgetsBinding.instance.addObserver(this);
    _cssInsets = readWebCssSafeAreaInsets();
    _safeAreaSubscription = listenWebSafeAreaChanges(_refreshCssInsets);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshCssInsets());
    // Flutter restores viewport-fit=cover after replacing the meta tag; insets
    // may only become non-zero a tick later.
    unawaited(Future<void>.delayed(const Duration(milliseconds: 50), _refreshCssInsets));
    unawaited(Future<void>.delayed(const Duration(milliseconds: 300), _refreshCssInsets));
  }

  @override
  void dispose() {
    if (kIsWeb) {
      WidgetsBinding.instance.removeObserver(this);
      _safeAreaSubscription?.cancel();
    }
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _refreshCssInsets();
  }

  void _refreshCssInsets() {
    if (!mounted || !kIsWeb) {
      return;
    }
    final next = readWebCssSafeAreaInsets();
    if (next == _cssInsets) {
      return;
    }
    setState(() => _cssInsets = next);
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return widget.child;
    }

    final cssInsets = _cssInsets;
    if (cssInsets == EdgeInsets.zero) {
      return widget.child;
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
      return widget.child;
    }

    return MediaQuery(
      data: data.copyWith(
        padding: nextPadding,
        viewPadding: nextViewPadding,
      ),
      child: widget.child,
    );
  }
}
