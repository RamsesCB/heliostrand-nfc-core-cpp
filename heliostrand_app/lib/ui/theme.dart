import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// THEO JANSEN SOLAR TRACKER - TEMA MINIMALISTA TRADICIONAL
///
/// Especificación visual:
/// - Fondo general: #F8F9FA
/// - Cards: Blanco puro #FFFFFF, radio 20px, borde #EFEFEF
/// - Acentos: Sol/Pitch #E9A000, Yaw #0EA5E9
/// - Estados: Equilibrado/Moviendo (#E6F4EA / #137333), Ajustando (#FEF3C7 / #92400E), Detenido (#FCE8E6 / #C5221F)
/// - Tipografía: Inter (Google Fonts)
class SolarTrackerTheme {
  // Paleta minimalista clara
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color cardBackground = Colors.white;
  static const Color cardBorder = Color(0xFFEFEFEF);
  static const Color subtleBorder = Color(0xFFE9ECEF);
  static const Color dividerColor = Color(0xFFF1F3F5);

  // Acentos de hardware y movimiento
  static const Color sunPitchAmber = Color(0xFFE9A000);
  static const Color yawSkyBlue = Color(0xFF0EA5E9);
  static const Color buttonDark = Color(0xFF111111);

  // Badges y semáforos
  static const Color badgeGreenBg = Color(0xFFE6F4EA);
  static const Color badgeGreenText = Color(0xFF137333);
  static const Color badgeAmberBg = Color(0xFFFEF3C7);
  static const Color badgeAmberText = Color(0xFF92400E);
  static const Color badgeRedBg = Color(0xFFFCE8E6);
  static const Color badgeRedText = Color(0xFFC5221F);

  // Escala de grises y textos
  static const Color textDark = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textTertiary = Color(0xFFADB5BD);

  // Compatibilidad con código existente
  static const Color primaryAmber = sunPitchAmber;
  static const Color accentCyan = yawSkyBlue;
  static const Color accentGreen = badgeGreenText;
  static const Color accentRed = badgeRedText;
  static const Color darkBackground = lightBackground;
  static const Color darkCard = cardBackground;

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

  // Alias para mantener compatibilidad con referencias existentes
  static ThemeData get darkTheme => lightTheme;
}

