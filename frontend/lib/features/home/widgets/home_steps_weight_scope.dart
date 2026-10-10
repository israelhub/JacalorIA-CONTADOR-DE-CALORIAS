import 'package:flutter/widgets.dart';

import '../controllers/home_steps_weight_controller.dart';

class HomeStepsWeightScope
    extends InheritedNotifier<HomeStepsWeightController> {
  const HomeStepsWeightScope({
    super.key,
    required HomeStepsWeightController controller,
    required super.child,
  }) : super(notifier: controller);

  static HomeStepsWeightController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<HomeStepsWeightScope>()
        ?.notifier;
  }

  static HomeStepsWeightController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'HomeStepsWeightScope não encontrado.');
    return controller!;
  }
}
