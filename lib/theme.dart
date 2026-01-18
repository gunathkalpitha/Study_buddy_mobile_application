import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: xl);
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
}

extension TextStyleContext on BuildContext {
  TextTheme get textStyles => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
}

extension TextStyleExtensions on TextStyle {
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);
  TextStyle get normal => copyWith(fontWeight: FontWeight.w400);
  TextStyle get light => copyWith(fontWeight: FontWeight.w300);
  TextStyle withColor(Color color) => copyWith(color: color);
  TextStyle withSize(double size) => copyWith(fontSize: size);
}

class LightModeColors {
  // Primary: Blue (#1976D2) - Better visibility
  static const lightPrimary = Color(0xFF1976D2);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFFBBDEFB);
  static const lightOnPrimaryContainer = Color(0xFF0D47A1);

  // Secondary: Teal (#00897B)
  static const lightSecondary = Color(0xFF00897B);
  static const lightOnSecondary = Color(0xFFFFFFFF);
  static const lightSecondaryContainer = Color(0xFFB2DFDB);
  static const lightOnSecondaryContainer = Color(0xFF004D40);

  // Tertiary: Deep Orange
  static const lightTertiary = Color(0xFFE64A19);
  static const lightOnTertiary = Color(0xFFFFFFFF);

  // Error
  static const lightError = Color(0xFFD32F2F);
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFFFCDD2);
  static const lightOnErrorContainer = Color(0xFFB71C1C);

  // Surface - Clean white with good contrast
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightOnSurface = Color(0xFF212121);
  static const lightBackground = Color(0xFFFAFAFA);
  static const lightSurfaceVariant = Color(0xFFF5F5F5);
  static const lightOnSurfaceVariant = Color(0xFF424242);
  static const lightOutline = Color(0xFFBDBDBD);
  static const lightShadow = Color(0xFF000000);
  static const lightInversePrimary = Color(0xFF64B5F6);
}

class DarkModeColors {
  // Primary
  static const darkPrimary = Color(0xFFD0BCFF);
  static const darkOnPrimary = Color(0xFF381E72);
  static const darkPrimaryContainer = Color(0xFF4F378B);
  static const darkOnPrimaryContainer = Color(0xFFEADDFF);

  // Secondary
  static const darkSecondary = Color(0xFFFFB74D);
  static const darkOnSecondary = Color(0xFF451C03); // Brownish
  static const darkSecondaryContainer = Color(0xFFE65100);
  static const darkOnSecondaryContainer = Color(0xFFFFE0B2);

  // Tertiary
  static const darkTertiary = Color(0xFFEFB8C8);
  static const darkOnTertiary = Color(0xFF492532);

  // Error
  static const darkError = Color(0xFFFFB4AB);
  static const darkOnError = Color(0xFF690005);
  static const darkErrorContainer = Color(0xFF93000A);
  static const darkOnErrorContainer = Color(0xFFFFDAD6);

  // Surface
  static const darkSurface = Color(0xFF1C1B1F);
  static const darkOnSurface = Color(0xFFE6E1E5);
  static const darkSurfaceVariant = Color(0xFF49454F);
  static const darkOnSurfaceVariant = Color(0xFFCAC4D0);
  static const darkOutline = Color(0xFF938F99);
  static const darkShadow = Color(0xFF000000);
  static const darkInversePrimary = Color(0xFF7B68EE);
}

class FontSizes {
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 28.0;
  static const double headlineSmall = 24.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = 16.0;
  static const double titleSmall = 14.0;
  static const double labelLarge = 14.0;
  static const double labelMedium = 12.0;
  static const double labelSmall = 11.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
}

ThemeData get lightTheme => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: LightModeColors.lightPrimary,
        onPrimary: LightModeColors.lightOnPrimary,
        primaryContainer: LightModeColors.lightPrimaryContainer,
        onPrimaryContainer: LightModeColors.lightOnPrimaryContainer,
        secondary: LightModeColors.lightSecondary,
        onSecondary: LightModeColors.lightOnSecondary,
        secondaryContainer: LightModeColors.lightSecondaryContainer,
        onSecondaryContainer: LightModeColors.lightOnSecondaryContainer,
        tertiary: LightModeColors.lightTertiary,
        onTertiary: LightModeColors.lightOnTertiary,
        error: LightModeColors.lightError,
        onError: LightModeColors.lightOnError,
        errorContainer: LightModeColors.lightErrorContainer,
        onErrorContainer: LightModeColors.lightOnErrorContainer,
        surface: LightModeColors.lightSurface,
        onSurface: LightModeColors.lightOnSurface,
        surfaceContainerHighest: LightModeColors.lightSurfaceVariant,
        onSurfaceVariant: LightModeColors.lightOnSurfaceVariant,
        outline: LightModeColors.lightOutline,
        shadow: LightModeColors.lightShadow,
        inversePrimary: LightModeColors.lightInversePrimary,
      ),
      brightness: Brightness.light,
      scaffoldBackgroundColor: LightModeColors.lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: LightModeColors.lightOnSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: LightModeColors.lightOutline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: LightModeColors.lightPrimary,
        foregroundColor: LightModeColors.lightOnPrimary,
        elevation: 2,
      ),
      textTheme: _buildTextTheme(Brightness.light),
    );

ThemeData get darkTheme => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: DarkModeColors.darkPrimary,
        onPrimary: DarkModeColors.darkOnPrimary,
        primaryContainer: DarkModeColors.darkPrimaryContainer,
        onPrimaryContainer: DarkModeColors.darkOnPrimaryContainer,
        secondary: DarkModeColors.darkSecondary,
        onSecondary: DarkModeColors.darkOnSecondary,
        secondaryContainer: DarkModeColors.darkSecondaryContainer,
        onSecondaryContainer: DarkModeColors.darkOnSecondaryContainer,
        tertiary: DarkModeColors.darkTertiary,
        onTertiary: DarkModeColors.darkOnTertiary,
        error: DarkModeColors.darkError,
        onError: DarkModeColors.darkOnError,
        errorContainer: DarkModeColors.darkErrorContainer,
        onErrorContainer: DarkModeColors.darkOnErrorContainer,
        surface: DarkModeColors.darkSurface,
        onSurface: DarkModeColors.darkOnSurface,
        surfaceContainerHighest: DarkModeColors.darkSurfaceVariant,
        onSurfaceVariant: DarkModeColors.darkOnSurfaceVariant,
        outline: DarkModeColors.darkOutline,
        shadow: DarkModeColors.darkShadow,
        inversePrimary: DarkModeColors.darkInversePrimary,
      ),
      brightness: Brightness.dark,
      scaffoldBackgroundColor: DarkModeColors.darkSurface,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: DarkModeColors.darkOnSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: DarkModeColors.darkOutline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: DarkModeColors.darkSecondary,
        foregroundColor: DarkModeColors.darkOnSecondary,
        elevation: 2,
      ),
      textTheme: _buildTextTheme(Brightness.dark),
    );

TextTheme _buildTextTheme(Brightness brightness) {
  return TextTheme(
    displayLarge: GoogleFonts.poppins(
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.w400,
    ),
    displayMedium: GoogleFonts.poppins(
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.w400,
    ),
    displaySmall: GoogleFonts.poppins(
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w400,
    ),
    headlineLarge: GoogleFonts.poppins(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.w600,
    ),
    headlineMedium: GoogleFonts.poppins(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: GoogleFonts.poppins(
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: GoogleFonts.poppins(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: GoogleFonts.poppins(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w500,
    ),
    titleSmall: GoogleFonts.poppins(
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: GoogleFonts.openSans(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: GoogleFonts.openSans(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.w400,
    ),
    bodySmall: GoogleFonts.openSans(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.w400,
    ),
    labelLarge: GoogleFonts.openSans(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w500,
    ),
    labelMedium: GoogleFonts.openSans(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: GoogleFonts.openSans(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w500,
    ),
  );
}
