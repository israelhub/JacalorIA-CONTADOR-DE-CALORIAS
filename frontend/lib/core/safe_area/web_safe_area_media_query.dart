import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'web_safe_area_insets.dart';

/// On Flutter Web, merges CSS `safe-area-inset-*` into [MediaQuery].
///
/// Native iOS/Android already populate [MediaQuery.viewPadding]. Flutter Web
/// usually reports zeros, so the bottom nav / toasts would sit under the home
/// indicator unless we copy the CSS env() values from `web/index.html`.
///
/// Top inset is intentionally ignored on web: with an opaque iOS status bar
/// (`apple-mobile-web-app-status-bar-style: black`) the layout already starts
/// below the status bar. Injecting top padding caused the whole chrome —
/// including the bottom nav — to sit too high above the system gesture bar.
class WebSafeAreaMediaQuery extends StatefulWidget {
  const WebSafeAreaMediaQuery({super.key, required this.child});

  final Widget child;

  @override
  State<WebSafeAreaMediaQuery> createState() => _WebSafeAreaMediaQueryState();
}

class _WebSafeAreaMediaQueryState extends State<WebSafeAreaMediaQuery>
    with WidgetsBindingObserver {
  EdgeInsets _cssInsets = EdgeInsets.zero;
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    WidgetsBinding.instance.addObserver(this);
    _cssInsets = readWebCssSafeAreaInsets();
    _subscription = listenWebSafeAreaChanges(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    unawaited(Future<void>.delayed(const Duration(milliseconds: 100), _refresh));
  }

  @override
  void dispose() {
    if (kIsWeb) {
      WidgetsBinding.instance.removeObserver(this);
      _subscription?.cancel();
    }
    super.dispose();
  }

  @override
  void didChangeMetrics() => _refresh();

  void _refresh() {
    if (!mounted || !kIsWeb) return;
    final next = readWebCssSafeAreaInsets();
    if (next == _cssInsets) return;
    setState(() => _cssInsets = next);
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return widget.child;

    // Bottom + horizontal only. Never inject top on web (see class doc).
    final bottom = _cssInsets.bottom;
    final left = _cssInsets.left;
    final right = _cssInsets.right;
    if (bottom <= 0 && left <= 0 && right <= 0) {
      return widget.child;
    }

    final data = MediaQuery.of(context);
    final nextPadding = EdgeInsets.only(
      left: math.max(data.padding.left, left),
      top: data.padding.top,
      right: math.max(data.padding.right, right),
      bottom: math.max(data.padding.bottom, bottom),
    );
    final nextViewPadding = EdgeInsets.only(
      left: math.max(data.viewPadding.left, left),
      top: data.viewPadding.top,
      right: math.max(data.viewPadding.right, right),
      bottom: math.max(data.viewPadding.bottom, bottom),
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
