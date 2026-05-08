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

  static const Color surface = Color(0xFFFFFFFD);
  static const Color textPrimary = Color(0xFF1D1B20);
  static const Color textSecondary = Color(0xFF717171);
  static const Color textMuted = Color(0xFF4D6559);
  static const Color textError = Color(0xFFB3261E);

  static const Color borderLight = Color(0xFFD6D6D6);
  static const Color borderAlt = Color(0xFFDDDDDD);
  static const Color inputBorder = Color(0xFFCED6D1);
  static const Color confirmationCodeBorder = Color(0xFFD4DDD8);
  static const Color borderBrand = Color.fromRGBO(30, 81, 62, 0.14);
  static const Color borderBrandAlt = Color.fromRGBO(30, 81, 62, 0.10);
  static const Color divider = Color(0xFFCAC4D0);
  static const Color inputSurface = Color(0xFFFFFFFD);
  static const Color surfaceAlt = Color(0xFFFAFAFA);
  static const Color textTertiary = Color(0xFFB0B0B0);
  static const Color foodReviewFieldBorder = Color(0xFFEFE3D7);
  static const Color foodReviewDeleteIcon = Color(0xFFE88D8D);
  static const Color foodReviewFieldShadow = Color(0x40000000);

  static const Color homeCardSurface = surface;
  static const Color homeMetaCardSurface = homeCardSurface;
  static const Color homeMetaCardBorder = Color(0xFFD4ECC4);
  static const Color homeMetaCardShadow = Color(0xFFB4CEA3);
  static const Color homeDashedBorder = Color(0xFFC4E4A8);
  static const Color homeMealCardBorder = foodReviewFieldBorder;
  static const Color homeMealCardShadow = foodReviewFieldShadow;
  static const Color homeProgressTrack = Color(0xFFE8F5E1);
  static const Color homeAddMealSurface = surface;
  static const Color homeMacroCarbs = action500;
  static const Color homeMacroProtein = Color(0xFFF4C842);
  static const Color homeMacroFat = Color(0xFFE86060);

  static const Color performanceCardBorder = Color(0xFFEFE3D7);
  static const Color performanceLegendMeal = Color(0xFFF4DB98);
  static const Color performanceLegendNoRecordBorder = Color(0xFFD9D9D9);
  static const Color performanceTrack = Color(0xFFF4F4F0);
  static const Color performanceMacroFat = Color(0xFFF2A8A8);

  static const Color missionsChallenge = Color(0xFFA855F7);
  static const Color missionsActionIconBg = Color.fromRGBO(124, 191, 77, 0.13);
  static const Color missionsAccentIconBg = Color.fromRGBO(227, 182, 64, 0.13);
  static const Color missionsChallengeIconBg = Color.fromRGBO(168, 85, 247, 0.13);
  static const Color missionsGoldPill = Color(0xFFFDF6E3);
  static const Color missionsXpPill = Color(0xFFEEF7E6);
  static const Color missionsIntroIcon = Color.fromRGBO(255, 255, 255, 0.20);
  static const Color missionsRewardGold = Color(0xFFB8902A);
  static const Color missionsRewardXp = Color(0xFF5FA036);

  static const Color socialMetricStreak = Color(0xFFF08A24);
  static const Color socialMetricFavoriteDish = Color(0xFF9EA7B3);
  static const Color socialMetricPreferredPeriod = Color(0xFF4D8BD6);
  static const Color socialMetricXp = Color(0xFF6F52C8);
  static const Color socialRankingSilver = Color(0xFF9EA7B3);
  static const Color socialRankingBronze = Color(0xFFB8793F);

  static const Color socialInfoBirthDateCandle = Color(0xFFFF5A5F);
  static const Color socialInfoBirthDateFilling = Color(0xFF32C7B0);
  static const Color socialInfoBirthDateBase = Color(0xFFF4B740);
  static const Color socialInfoSex = Color(0xFF3B82F6);
  static const Color socialInfoObjective = Color(0xFF14B8A6);

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

  static TextStyle get performanceTitle => GoogleFonts.baloo2(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 36 / 28,
  );

  static TextStyle get performanceSectionTitle => GoogleFonts.baloo2(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
  );

  static TextStyle get performanceMonthTitle => GoogleFonts.baloo2(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 26 / 18,
  );

  static TextStyle get performanceCardCaption => GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 18 / 12,
  );

  static TextStyle get performanceCardValue => GoogleFonts.baloo2(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 27.5 / 22,
  );

  static TextStyle get performanceCardMicro => GoogleFonts.nunito(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 16.5 / 11,
  );

  static TextStyle get performanceDayNumber => GoogleFonts.nunito(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 19.5 / 13,
  );

  static TextStyle get performanceHighlightTitle => GoogleFonts.baloo2(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 24 / 16,
  );

  static TextStyle get performanceBody => GoogleFonts.nunito(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 17.875 / 13,
  );

  static TextStyle get performanceMacroLabel => GoogleFonts.nunito(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 16.5 / 11,
  );

  static TextStyle get performanceStreakLabel => GoogleFonts.nunito(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 19.5 / 13,
  );

  static TextStyle get performanceStreakValue => GoogleFonts.baloo2(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 45 / 36,
  );

  static TextStyle get performanceStreakMicro => GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 18 / 12,
  );

  static TextStyle get missionsTitle => GoogleFonts.baloo2(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 36 / 28,
    letterSpacing: -0.28,
  );

  static TextStyle get missionsSectionTitle => GoogleFonts.baloo2(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
    letterSpacing: -0.1,
  );

  static TextStyle get missionsSectionSubtitle => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 18 / 12,
  );

  static TextStyle get missionsCardTitle => GoogleFonts.baloo2(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 26 / 18,
    letterSpacing: -0.045,
  );

  static TextStyle get missionsCardDescription => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 16 / 11,
    letterSpacing: 0.0825,
  );

  static TextStyle get missionsProgress => GoogleFonts.nunito(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 16.5 / 11,
  );

  static TextStyle get missionsRewardGold => GoogleFonts.baloo2(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 19.5 / 13,
    color: AppColors.missionsRewardGold,
  );

  static TextStyle get missionsRewardXp => GoogleFonts.baloo2(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 19.5 / 13,
    color: AppColors.missionsRewardXp,
  );

  static TextStyle get missionsPillValue => GoogleFonts.baloo2(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 21 / 14,
  );

  static TextStyle get socialResultAction => GoogleFonts.baloo2(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 14 / 11,
  );

  static TextStyle get missionsIntroTitle => GoogleFonts.baloo2(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
    letterSpacing: -0.1,
  );

  static TextStyle get missionsIntroDescription => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 18 / 12,
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
      offset: Offset(0, 4),
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

  static const List<BoxShadow> foodReviewField = [
    BoxShadow(
      color: AppColors.foodReviewFieldShadow,
      offset: Offset(0, 4),
      blurRadius: 0,
    ),
  ];

  static const List<BoxShadow> performanceCard = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.08),
      offset: Offset(0, 4),
      blurRadius: 0,
    ),
  ];

  static const List<BoxShadow> performanceStreak = [
    BoxShadow(
      color: AppColors.action500Shadow,
      offset: Offset(0, 4),
      blurRadius: 0,
    ),
  ];

  static const List<BoxShadow> missionsIntro = [
    BoxShadow(
      color: AppColors.action500Shadow,
      offset: Offset(0, 4),
      blurRadius: 0,
    ),
  ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        headlineLarge: AppTextStyles.headingLarge,
        headlineMedium: AppTextStyles.headingMedium,
        headlineSmall: AppTextStyles.headingSmall,
        titleLarge: AppTextStyles.subtitleLarge,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.label,
        labelMedium: AppTextStyles.caption,
        labelSmall: AppTextStyles.micro,
      ),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
    );
  }
}
