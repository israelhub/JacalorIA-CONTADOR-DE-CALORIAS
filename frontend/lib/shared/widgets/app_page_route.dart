import 'package:flutter/material.dart';

/// Transição de página com slide horizontal (arrastar para o lado).
/// Use [AppPageRoute] no lugar de [MaterialPageRoute] para uma animação
/// consistente em todo o app.
///
/// Exemplo:
/// ```dart
/// Navigator.of(context).push(AppPageRoute(builder: (_) => MyPage()));
/// ```
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({
    required WidgetBuilder builder,
    super.settings,
    super.fullscreenDialog,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            final tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            final slideTween = animation.drive(tween);

            // Saída com leve deslocamento para a esquerda
            final secondaryTween = Tween(
              begin: Offset.zero,
              end: const Offset(-0.25, 0.0),
            ).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: slideTween,
              child: SlideTransition(
                position: secondaryAnimation.drive(secondaryTween),
                child: child,
              ),
            );
          },
        );
}

extension AppPageRouteNavigation on BuildContext {
  Future<T?> pushSlidePage<T>(Widget page) {
    return Navigator.of(this).push<T>(
      AppPageRoute(builder: (_) => page),
    );
  }

  Future<T?> pushAndRemoveUntilSlidePage<T>(
    Widget page,
    RoutePredicate predicate,
  ) {
    return Navigator.of(this).pushAndRemoveUntil<T>(
      AppPageRoute(builder: (_) => page),
      predicate,
    );
  }
}
