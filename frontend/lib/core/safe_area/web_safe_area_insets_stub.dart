import 'dart:async';

import 'package:flutter/widgets.dart';

EdgeInsets readWebCssSafeAreaInsets() => EdgeInsets.zero;

StreamSubscription<void> listenWebSafeAreaChanges(void Function() onChanged) {
  return const Stream<void>.empty().listen((_) {});
}
