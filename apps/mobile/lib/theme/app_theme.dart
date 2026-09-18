import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for QuranEcho.
///
/// Palette is drawn from illuminated Quran manuscripts: parchment paper,
/// deep pine-green ink, and a muted gold used sparingly for achievement
/// and emphasis. Deliberately avoids neon/teal gradients and near-black
/// "app chrome" backgrounds.
class AppColors {
  AppColors._();

  // Light surfaces
  static const Color parchment = Color(0xFFF6F1E3);
  static const Color parchmentRaised = Color(0xFFEFE6CF);
  static const Color card = Color(0xFFFFFDF8);

  // Light text
  static const Color ink = Color(0xFF17241D);
  static const Color inkSoft = Color(0xFF57685C);

  // Brand green
  static const Color palm = Color(0xFF1E5B45);
  static const Color palmDeep = Color(0xFF123B2C);
  static const Color palmSoft = Color(0xFFDCE8DE);
  static const Color sage = Color(0xFF7C9A82);

  // Accents
  static const Color gold = Color(0xFFAD7F2C);
  static const Color goldSoft = Color(0xFFF1E4C3);
  static const Color clay = Color(0xFFA5432F);
  static const Color claySoft = Color(0xFFF3DED8);

  static const Color line = Color(0xFFDED2B4);

  // Dark surfaces
  static const Color darkBg = Color(0xFF101A14);
  static const Color darkSurface = Color(0xFF17241D);
  static const Color darkCard = Color(0xFF1D2C23);
  static const Color darkText = Color(0xFFEDE7D6);
  static const Color darkTextSoft = Color(0xFFAEB8AC);
  static const Color darkPalm = Color(0xFF4FA07C);
  static const Color darkGold = Color(0xFFD3A94F);
  static const Color darkClay = Color(0xFFD98369);
  static const Color darkLine = Color(0xFF2C3B31);
}

/// Consistent spacing scale used across pages.
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// One shared corner radius so cards, fields, and sheets read as one system.
class AppRadius {
  AppRadius._();
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static BorderRadius get smBorder => BorderRadius.circular(sm);
  static BorderRadius get mdBorder => BorderRadius.circular(md);
  static BorderRadius get lgBorder => BorderRadius.circular(lg);
}

class AppTheme {
  AppTheme._();

  static TextTheme _textTheme(Color headingColor, Color bodyColor) {
    final base = GoogleFonts.publicSansTextTheme().apply(
      bodyColor: bodyColor,
      displayColor: headingColor,
    );
    final display = GoogleFonts.frauncesTextTheme();
    return base.copyWith(
      displayLarge: display.displayLarge?.copyWith(
        color: headingColor,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      displayMedium: display.displayMedium?.copyWith(
        color: headingColor,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: display.headlineLarge?.copyWith(
        color: headingColor,
        fontWeight: FontWeight.w600,
        fontSize: 30,
      ),
      headlineMedium: display.headlineMedium?.copyWith(
        color: headingColor,
        fontWeight: FontWeight.w600,
        fontSize: 24,
      ),
      headlineSmall: display.headlineSmall?.copyWith(
        color: headingColor,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      titleLarge: base.titleLarge?.copyWith(
        color: headingColor,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: headingColor,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.titleSmall?.copyWith(
        color: headingColor,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.bodyLarge?.copyWith(height: 1.5),
      bodyMedium: base.bodyMedium?.copyWith(height: 1.5),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  static ThemeData light() {
    const primary = AppColors.palm;
    final textTheme = _textTheme(AppColors.ink, AppColors.ink);

    final colorScheme = const ColorScheme.light().copyWith(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: AppColors.parchment,
      primaryContainer: AppColors.palmSoft,
      onPrimaryContainer: AppColors.palmDeep,
      secondary: AppColors.gold,
      onSecondary: Colors.white,
      surface: AppColors.card,
      onSurface: AppColors.ink,
      error: AppColors.clay,
      onError: Colors.white,
      outline: AppColors.line,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.parchment,
      textTheme: textTheme,
      dividerColor: AppColors.line,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.palm,
        foregroundColor: AppColors.parchment,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.parchment,
        ),
        iconTheme: const IconThemeData(color: AppColors.parchment),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdBorder,
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.palm,
          foregroundColor: AppColors.parchment,
          disabledBackgroundColor: AppColors.sage.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smBorder),
          textStyle: GoogleFonts.publicSans(fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.palm,
          side: const BorderSide(color: AppColors.palm),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smBorder),
          textStyle: GoogleFonts.publicSans(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.palm,
          textStyle: GoogleFonts.publicSans(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadius.smBorder,
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smBorder,
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smBorder,
          borderSide: const BorderSide(color: AppColors.palm, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.smBorder,
          borderSide: const BorderSide(color: AppColors.clay),
        ),
        labelStyle: GoogleFonts.publicSans(color: AppColors.inkSoft),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        contentTextStyle: GoogleFonts.publicSans(
          fontSize: 15,
          color: AppColors.ink,
          height: 1.5,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.palmDeep,
        contentTextStyle: GoogleFonts.publicSans(color: AppColors.parchment),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smBorder),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.palm,
        linearTrackColor: AppColors.palmSoft,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.ink),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
      ),
    );
  }

  static ThemeData dark() {
    final textTheme = _textTheme(AppColors.darkText, AppColors.darkText);

    final colorScheme = const ColorScheme.dark().copyWith(
      brightness: Brightness.dark,
      primary: AppColors.darkPalm,
      onPrimary: AppColors.darkBg,
      primaryContainer: AppColors.darkSurface,
      onPrimaryContainer: AppColors.darkText,
      secondary: AppColors.darkGold,
      onSecondary: AppColors.darkBg,
      surface: AppColors.darkCard,
      onSurface: AppColors.darkText,
      error: AppColors.darkClay,
      onError: AppColors.darkBg,
      outline: AppColors.darkLine,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBg,
      textTheme: textTheme,
      dividerColor: AppColors.darkLine,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdBorder,
          side: const BorderSide(color: AppColors.darkLine),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPalm,
          foregroundColor: AppColors.darkBg,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smBorder),
          textStyle: GoogleFonts.publicSans(fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkPalm,
          side: const BorderSide(color: AppColors.darkPalm),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smBorder),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.darkPalm),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadius.smBorder,
          borderSide: const BorderSide(color: AppColors.darkLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smBorder,
          borderSide: const BorderSide(color: AppColors.darkLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smBorder,
          borderSide: const BorderSide(color: AppColors.darkPalm, width: 1.5),
        ),
        labelStyle: GoogleFonts.publicSans(color: AppColors.darkTextSoft),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
        ),
        contentTextStyle: GoogleFonts.publicSans(
          fontSize: 15,
          color: AppColors.darkText,
          height: 1.5,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkPalm,
        contentTextStyle: GoogleFonts.publicSans(color: AppColors.darkBg),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smBorder),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.darkPalm,
        linearTrackColor: AppColors.darkLine,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkLine,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.darkText),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
      ),
    );
  }
}
