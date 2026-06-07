import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color black = Color(0xFF000000);
  static const Color blue = Color(0xFF295282);
  static const Color navyBlue = Color(0xFF00224A); 
  static const Color veryDarkBlue = Color(0xFF040C16);
  static const Color limeGreen = Color(0xFF9CCE00);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFCCCCCC);
  static const Color darkNavy = Color(0xFF0A1628);
  static const Color inputPlceholder = Color(0xFFCFCFCF);
  static const Color neonLime = Color(0xFFD3FE4C);
  static const Color brightLimeGreen = Color(0xFFCCFD33);
  static const Color mediumShadeGreen = Color(0xFF8BB702);
  static const Color lightLimeGreen = Color(0xFFCCE482);
  static const Color lightMintGreen = Color(0xFFF6FEDE);
  static const Color darkTealGreen = Color(0xFF015947);
  static const Color darkOliveGreen = Color(0xFF3A4B06);
  static const Color mutedOliveGreen= Color(0xFFCFDBA9);
  static const Color mediumGray = Color(0xFF737373);
  static const Color darkGray = Color(0xFF191919);
  static const Color ivoryTint = Color(0xFFFCFFF3);
  static const Color softYellowGreen = Color(0xFFE7FF9D);

}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: AppColors.limeGreen,
        surface: AppColors.navyBlue,
      ),
      scaffoldBackgroundColor: AppColors.navyBlue,
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: AppColors.white,
        displayColor: AppColors.white,
      ),
    );
  }
}
