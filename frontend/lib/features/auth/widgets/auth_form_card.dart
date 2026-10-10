import 'package:flutter/material.dart';

import '../../../shared/widgets/app_form_card.dart';

class AuthFormCard extends StatelessWidget {
  const AuthFormCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppFormCard(child: child);
  }
}
