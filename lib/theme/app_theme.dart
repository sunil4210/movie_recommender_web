import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_recommender_web/theme/app_color.dart';

class AppTheme {
  static ThemeData primaryTheme = ThemeData(
    colorSchemeSeed: AppColors.primary,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.scaffoldBackground,
    fontFamily: GoogleFonts.poppins().fontFamily,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 32, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
      headlineMedium: TextStyle(fontSize: 28, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(fontSize: 24, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 20, color: AppColors.textPrimary),
      bodyMedium: TextStyle(fontSize: 16, color: AppColors.textPrimary),
      bodySmall: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      labelLarge: TextStyle(fontSize: 16, color: AppColors.textPrimary),
      labelMedium: TextStyle(fontSize: 14, color: AppColors.textPrimary),
      labelSmall: TextStyle(fontSize: 12, color: AppColors.textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: const WidgetStatePropertyAll<Color>(AppColors.buttonPrimary),
        foregroundColor: const WidgetStatePropertyAll<Color>(AppColors.colorWhite),
        shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        textStyle: const WidgetStatePropertyAll<TextStyle>(TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.borderColor, thickness: 1, space: 0),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        overlayColor: WidgetStateProperty.all<Color>(AppColors.primary.withValues(alpha: 0.1)),
        foregroundColor: WidgetStateProperty.all<Color>(AppColors.textPrimary),
        textStyle: WidgetStateProperty.all<TextStyle>(const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        padding: WidgetStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
        overlayColor: WidgetStateProperty.all<Color>(AppColors.primary.withValues(alpha: 0.1)),
        foregroundColor: WidgetStateProperty.all<Color>(AppColors.textPrimary),
        textStyle: WidgetStateProperty.all<TextStyle>(const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        side: WidgetStateProperty.all<BorderSide>(const BorderSide(color: AppColors.border)),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      indicator: UnderlineTabIndicator(borderSide: BorderSide(color: AppColors.primary, width: 2)),
      indicatorColor: AppColors.primary,
      dividerColor: AppColors.border,
      dividerHeight: 1,
      labelColor: AppColors.primary,
      tabAlignment: TabAlignment.start,
      unselectedLabelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.grey500),
      labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: AppColors.primary.withValues(alpha: 0.3),
      selectionHandleColor: AppColors.primary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.backgroundCard,
      hintStyle: const TextStyle(color: AppColors.textDisabled, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}
