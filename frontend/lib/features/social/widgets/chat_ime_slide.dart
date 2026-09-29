import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Desliza o chat junto com o teclado sem relayout, como Telegram e WhatsApp.
///
/// A altura do conteudo nunca muda: o teclado so vira um translate, entao a
/// lista de mensagens nao refaz layout a cada frame da animacao do IME.
class ChatKeyboardLift extends StatefulWidget {
  const ChatKeyboardLift({super.key, required this.child});

  final Widget child;

  @override
  State<ChatKeyboardLift> createState() => _ChatKeyboardLiftState();
}

class _ChatKeyboardLiftState extends State<ChatKeyboardLift> {
  double _restingHeight = 0;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final viewPaddingBottom = MediaQuery.viewPaddingOf(context).bottom;
    if (inset == 0 || height > _restingHeight) {
      _restingHeight = height;
    }

    // Android antigo encolhe a janela com o teclado; ai o inset ja foi pago
    // pelo resize e subir de novo criaria um vao duplo.
    final shrunk = math.max(0.0, _restingHeight - height);
    final lift = math.max(0.0, inset - shrunk - viewPaddingBottom);

    // A raiz precisa ser sempre o mesmo widget: trocar Transform por outro
    // tipo recria a subarvore inteira, derruba o foco do TextField e fecha
    // o teclado logo depois de abrir.
    return Transform.translate(
      offset: Offset(0, -lift),
      filterQuality: FilterQuality.none,
      child: RepaintBoundary(child: widget.child),
    );
  }
}

class ChatViewPadding extends StatelessWidget {
  const ChatViewPadding({super.key, required this.top});

  final bool top;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.viewPaddingOf(context);
    return SizedBox(height: top ? padding.top : padding.bottom);
  }
}
