import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'features/auth/pages/enter_page.dart';
import 'features/auth/service/auth_service.dart';
import 'features/home/pages/home_shell_page.dart';
import 'shared/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.initialize();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarDividerColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const _systemUiOverlayStyle = SystemUiOverlayStyle(
    systemNavigationBarColor: AppColors.surface,
    systemNavigationBarDividerColor: AppColors.surface,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _systemUiOverlayStyle,
      child: MaterialApp(
        title: 'JacalorIA',
        debugShowCheckedModeBanner: false,
        home: AuthService.globalToken != null
            ? const HomeShellPage()
            : const EnterPage(),
      ),
    );
  }
}
