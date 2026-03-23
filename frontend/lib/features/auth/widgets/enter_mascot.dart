import 'package:flutter/material.dart';

class EnterMascot extends StatelessWidget {
  const EnterMascot({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      width: double.infinity,
      child: Align(
        alignment: Alignment.centerRight,
        child: Image.asset(
          'assets/images/jacaTelaCadastro.png',
          width: 204,
          height: 320,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
