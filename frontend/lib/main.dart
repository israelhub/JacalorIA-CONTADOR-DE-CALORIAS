import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/analytics/analytics_service.dart';
import 'core/invite/invite_link_service.dart';
import 'core/notifications/meal_reminder_service.dart';
import 'core/safe_area/web_safe_area_media_query.dart';
import 'features/auth/pages/enter_page.dart';
import 'features/auth/service/auth_service.dart';
import 'features/home/pages/home_shell_page.dart';
import 'shared/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Bundle fonts under assets/google_fonts and never swap mid-frame (FOUT).
  GoogleFonts.config.allowRuntimeFetching = false;
  await GoogleFonts.pendingFonts(<TextStyle>[
    GoogleFonts.baloo2(),
    GoogleFonts.baloo2(fontWeight: FontWeight.w600),
    GoogleFonts.baloo2(fontWeight: FontWeight.w700),
    GoogleFonts.baloo2(fontWeight: FontWeight.w800),
    GoogleFonts.nunito(),
    GoogleFonts.nunito(fontWeight: FontWeight.w500),
    GoogleFonts.nunito(fontWeight: FontWeight.w600),
    GoogleFonts.nunito(fontWeight: FontWeight.w700),
    GoogleFonts.nunito(fontWeight: FontWeight.w800),
    GoogleFonts.inter(),
    GoogleFonts.inter(fontWeight: FontWeight.w500),
    GoogleFonts.inter(fontWeight: FontWeight.w600),
  ]);
  InviteLinkService.captureFromUri(Uri.base);
  await AuthService.initialize();
  _warmUpAvatarCache();
  unawaited(AnalyticsService.instance.initialize());
  unawaited(_bootstrapMealReminders());
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ]);
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarDividerColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

Future<void> _bootstrapMealReminders() async {
  if (AuthService.globalToken == null) {
    return;
  }
  try {
    await MealReminderService.instance.initialize();
    // Na web não pedir permissão no boot (browser exige gesto do usuário).
    await MealReminderService.instance.syncScheduledReminders(
      requestPermission: false,
    );
  } catch (_) {}
}

/// Começa a baixar a foto de perfil para o cache em disco assim que o app
/// abre, em paralelo com o resto do boot, para o avatar aparecer mais rápido
/// na primeira sessão. No web o cache HTTP do navegador já cobre isso.
void _warmUpAvatarCache() {
  if (kIsWeb) {
    return;
  }

  final user = AuthService.globalUser;
  final avatarUrl = (user?['avatarUrl'] ?? user?['avatar_url'])
      ?.toString()
      .trim();
  if (avatarUrl == null || !avatarUrl.startsWith('http')) {
    return;
  }

  Future<void>(() async {
    try {
      await DefaultCacheManager().getSingleFile(avatarUrl);
    } catch (_) {}
  });
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
          return WebSafeAreaMediaQuery(child: child ?? const SizedBox.shrink());
        },
        home: AuthService.globalToken != null
            ? HomeShellPage.fromLaunch()
            : const EnterPage(),
      ),
    );
  }
}
