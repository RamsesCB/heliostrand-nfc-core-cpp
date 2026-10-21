import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SolarTrackerTheme {
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color cardBackground = Colors.white;
  static const Color cardBorder = Color(0xFFEFEFEF);
  static const Color subtleBorder = Color(0xFFE9ECEF);

  static const Color sunPitchAmber = Color(0xFFE9A000);
  static const Color yawSkyBlue = Color(0xFF0EA5E9);
  static const Color buttonDark = Color(0xFF111111);

  static const Color badgeGreenBg = Color(0xFFE6F4EA);
  static const Color badgeGreenText = Color(0xFF137333);
  static const Color badgeAmberBg = Color(0xFFFEF3C7);
  static const Color badgeAmberText = Color(0xFF92400E);
  static const Color badgeRedBg = Color(0xFFFCE8E6);
  static const Color badgeRedText = Color(0xFFC5221F);

  static const Color textDark = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textTertiary = Color(0xFFADB5BD);

  static ThemeData get lightTheme {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: ColorScheme.light(
        primary: buttonDark,
        secondary: sunPitchAmber,
        surface: cardBackground,
        onSurface: textDark,
        error: badgeRedText,
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        iconTheme: const IconThemeData(color: textDark),
      ),
      sliderTheme: const SliderThemeData(
        trackHeight: 4,
        activeTrackColor: sunPitchAmber,
        inactiveTrackColor: subtleBorder,
        thumbColor: Colors.white,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 9, elevation: 2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
    );
  }
}
