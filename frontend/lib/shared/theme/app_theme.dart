import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const Color brand900 = Color(0xFF1E513E);
  static const Color brand900Variant = Color(0xFF193629);
  static const Color brand300 = Color(0xFFCFF2BA);

  static const Color accent500 = Color(0xFFE3B640);

  static const Color action500 = Color(0xFF7CBF4D);
  static const Color action500Shadow = Color(0xFF1E513E);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1D1B20);
  static const Color textSecondary = Color(0xFF717171);
  static const Color textMuted = Color(0xFF4D6559);
  static const Color textError = Color(0xFFB3261E);

  static const Color borderLight = Color(0xFFD6D6D6);
  static const Color borderAlt = Color(0xFFDDDDDD);
  static const Color borderBrand = Color.fromRGBO(30, 81, 62, 0.14);
  static const Color borderBrandAlt = Color.fromRGBO(30, 81, 62, 0.10);
  static const Color divider = Color(0xFFCAC4D0);
  static const Color inputSurface = Color(0xFFEAEAEA);
  static const Color surfaceAlt = Color(0xFFFAFAFA);
  static const Color textTertiary = Color(0xFFB0B0B0);

  static const Color homeMetaCardSurface = Color(0xFFF5FAF0);
  static const Color homeMetaCardBorder = Color(0xFFD4ECC4);
  static const Color homeMetaCardShadow = Color(0xFFB4CEA3);
  static const Color homeDashedBorder = Color(0xFFC4E4A8);
  static const Color homeMealCardBorder = Color(0xFFEBEBEB);
  static const Color homeMealCardShadow = Color(0xFFE8E8E8);
  static const Color homeProgressTrack = Color(0xFFE8F5E1);
  static const Color homeMacroCarbs = action500;
  static const Color homeMacroProtein = Color(0xFFF4C842);
  static const Color homeMacroFat = Color(0xFFE86060);

  static const Color shadowButton = Color(0xFFC0C0C0);
  static const Color shadowButtonAlt = Color(0xFFDFDFDF);

  static const Color primary = action500;
  static const Color primaryShadow = action500Shadow;
  static const Color background = surface;
  static const Color shadowLight = shadowButton;
  static const Color shadowAlt = shadowButtonAlt;
  static const Color bottomBar = brand900;
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displayLarge => GoogleFonts.baloo2(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 48 / 40,
  );

  static TextStyle get headingLarge =>
      GoogleFonts.baloo2(fontSize: 36, fontWeight: FontWeight.w700, height: 1);

  static TextStyle get headingMedium => GoogleFonts.baloo2(
    fontSize: 28.8,
    fontWeight: FontWeight.w700,
    height: 1,
  );

  static TextStyle get confirmationTitle => GoogleFonts.baloo2(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 36.8 / 32,
  );

  static TextStyle get confirmationResendLink => GoogleFonts.nunito(
    fontSize: 13.76,
    fontWeight: FontWeight.w600,
    height: 19.952 / 13.76,
  );

  static TextStyle get headingSmall => GoogleFonts.baloo2(
    fontSize: 20.8,
    fontWeight: FontWeight.w700,
    height: 1,
  );

  static TextStyle get subtitleLarge =>
      GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w600, height: 1);

  static TextStyle get buttonLarge =>
      GoogleFonts.baloo2(fontSize: 20, fontWeight: FontWeight.w700, height: 1);

  static TextStyle get buttonMedium =>
      GoogleFonts.baloo2(fontSize: 18, fontWeight: FontWeight.w700, height: 1);

  static TextStyle get buttonSmall => GoogleFonts.nunito(
    fontSize: 13.333,
    fontWeight: FontWeight.w800,
    height: 1,
  );

  static TextStyle get bodyLarge => GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 23.2 / 16,
  );

  static TextStyle get bodyMedium => GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 19.952 / 14,
  );

  static TextStyle get bodySmall => GoogleFonts.nunito(
    fontSize: 13.76,
    fontWeight: FontWeight.w400,
    height: 20 / 13.76,
  );

  static TextStyle get label =>
      GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, height: 1);

  static TextStyle get labelField => GoogleFonts.nunito(
    fontSize: 14.08,
    fontWeight: FontWeight.w700,
    height: 1,
  );

  static TextStyle get caption => GoogleFonts.nunito(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 16 / 13,
  );

  static TextStyle get captionStrong => GoogleFonts.nunito(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 14 / 11,
  );

  static TextStyle get micro => GoogleFonts.nunito(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 12 / 10,
  );

  static TextStyle get statValue => GoogleFonts.baloo2(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 20 / 16,
  );

  static TextStyle get homeHello => GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 18 / 14,
  );

  static TextStyle get homeUserName => GoogleFonts.baloo2(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 26 / 24,
  );

  static TextStyle get homeSectionTitle => GoogleFonts.baloo2(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 22 / 18,
  );

  static TextStyle get homeAction => GoogleFonts.baloo2(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 18 / 15,
  );

  static TextStyle get homeMealTitle => GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 18 / 14,
  );

  static TextStyle get homeMealSubtitle => GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
  );

  static TextStyle get homeMealKcal => GoogleFonts.baloo2(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 18 / 14,
  );

  static TextStyle get homeBottomNav => GoogleFonts.nunito(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 14 / 11,
  );
}

class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
}

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color.fromRGBO(30, 81, 62, 0.08),
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color.fromRGBO(30, 81, 62, 0.14),
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
  ];

  static const List<BoxShadow> homeMetaCard = [
    BoxShadow(
      color: AppColors.homeMetaCardShadow,
      offset: Offset(0, 4),
      blurRadius: 0,
    ),
  ];

  static const List<BoxShadow> homeMealCard = [
    BoxShadow(
      color: AppColors.homeMealCardShadow,
      offset: Offset(0, 2),
      blurRadius: 0,
    ),
  ];

  static const List<BoxShadow> homeActionCircle = [
    BoxShadow(
      color: AppColors.action500Shadow,
      offset: Offset(0, 4),
      blurRadius: 0,
    ),
  ];
}
