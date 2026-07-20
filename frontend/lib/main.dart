import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';

import 'core/analytics/analytics_service.dart';
import 'core/invite/invite_link_service.dart';
import 'core/safe_area/web_safe_area_media_query.dart';
import 'features/auth/pages/enter_page.dart';
import 'features/auth/service/auth_service.dart';
import 'features/home/pages/home_shell_page.dart';
import 'shared/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  InviteLinkService.captureFromUri(Uri.base);
  await AuthService.initialize();
  await AnalyticsService.instance.initialize();
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

  static const _appLocale = Locale('pt', 'BR');
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
        locale: _appLocale,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const <Locale>[_appLocale],
        builder: (context, child) {
          return WebSafeAreaMediaQuery(
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: AuthService.globalToken != null
            ? HomeShellPage.fromLaunch()
            : const EnterPage(),
      ),
    );
  }
}
