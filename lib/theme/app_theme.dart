import 'package:flutter/material.dart';
import 'app_colors.dart';

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    tertiary: AppColors.accent,
    background: AppColors.bg,
    surface: AppColors.surface,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppColors.onSurface,
    brightness: Brightness.dark,
  );

  final radius = BorderRadius.circular(16);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.onSurface,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: radius),
      titleTextStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: AppColors.onSurface,
      ),
      contentTextStyle: const TextStyle(
        fontSize: 14,
        color: AppColors.onSurface,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF192231),
      labelStyle: TextStyle(color: AppColors.onSurfaceMuted),
      hintStyle: TextStyle(color: AppColors.onSurfaceMuted),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.onSurfaceMuted.withOpacity(.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.onSurfaceMuted.withOpacity(.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.secondary, width: 1.6),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: radius),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        elevation: 0,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: radius),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.onSurface),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primary.withOpacity(.2),
      labelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      shape: StadiumBorder(
        side: BorderSide(color: AppColors.primary.withOpacity(.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    dividerTheme: DividerThemeData(color: Colors.white.withOpacity(.08)),
  );
}
