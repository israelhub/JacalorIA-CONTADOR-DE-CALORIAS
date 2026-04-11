import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'features/auth/pages/enter_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
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
