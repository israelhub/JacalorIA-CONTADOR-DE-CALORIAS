import 'package:flutter/material.dart';

import 'features/auth/pages/enter_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'JacalorIA',
      debugShowCheckedModeBanner: false,
      home: EnterPage(),
    );
  }
}
