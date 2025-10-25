// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: const Color(0xFF0EA5E9),
      onSecondary: Colors.white,
      error: const Color(0xFFDC2626),
      onError: Colors.white,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.contentLight,
      surfaceContainerHighest: AppColors.borderLight,
      onSurfaceVariant: AppColors.subtleLight,
      outline: AppColors.borderLight,
      shadow: Colors.black.withOpacity(0.2),
      tertiary: const Color(0xFF22C55E),
      onTertiary: Colors.white,
      inversePrimary: AppColors.contentLight,
      inverseSurface: AppColors.backgroundLight,
      scrim: Colors.black54,
    ),
    scaffoldBackgroundColor: AppColors.backgroundLight,
    fontFamily: 'Inter',
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: const Color(0xFF38BDF8),
      onSecondary: Colors.black,
      error: const Color(0xFFF87171),
      onError: Colors.black,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.contentDark,
      surfaceContainerHighest: AppColors.borderDark,
      onSurfaceVariant: AppColors.subtleDark,
      outline: AppColors.borderDark,
      shadow: Colors.black,
      tertiary: const Color(0xFF22C55E),
      onTertiary: Colors.black,
      inversePrimary: AppColors.contentDark,
      inverseSurface: AppColors.backgroundDark,
      scrim: Colors.black87,
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    fontFamily: 'Inter',
  );
}
