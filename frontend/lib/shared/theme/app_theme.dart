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
}
