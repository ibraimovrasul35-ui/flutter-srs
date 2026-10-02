import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';

/// Светлая и тёмная темы, собранные из AppColors.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(
    brightness: Brightness.light,
    background: AppColors.background,
    surface: AppColors.surface,
    text: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    divider: AppColors.divider,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    background: AppColors.backgroundDark,
    surface: AppColors.surfaceDark,
    text: AppColors.textPrimaryDark,
    textSecondary: AppColors.textSecondaryDark,
    divider: AppColors.dividerDark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color text,
    required Color textSecondary,
    required Color divider,
  }) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: brightness,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: AppColors.white,
          secondary: AppColors.accent,
          surface: surface,
          onSurface: text,
          onSurfaceVariant: textSecondary,
          outlineVariant: divider,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      dividerColor: divider,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: background,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 22.sp,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
    );
  }
}
