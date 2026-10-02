import 'package:flutter/material.dart';

/// Все цвета приложения в одном месте.
class AppColors {
  AppColors._();

  // Основные
  static const primary = Color(0xFF2196F3);
  static const primaryDark = Color(0xFF1565C0);
  static const accent = Color(0xFFFF7043);
  static const favorite = Color(0xFFE53935);

  // Светлая тема
  static const background = Color(0xFFF5F5F5);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const divider = Color(0xFFE0E0E0);

  // Тёмная тема
  static const backgroundDark = Color(0xFF121212);
  static const surfaceDark = Color(0xFF1E1E1E);
  static const textPrimaryDark = Color(0xFFEEEEEE);
  static const textSecondaryDark = Color(0xFFB0B0B0);
  static const dividerDark = Color(0xFF2C2C2C);

  // Общие
  static const white = Color(0xFFFFFFFF);
  static const shadow = Color(0x1A000000);
  static const whiteTransparent = Color(0x33FFFFFF);

  // Цвета карточек на главной
  static const cardBlue = Color(0xFF42A5F5);
  static const cardOrange = Color(0xFFFF8A65);
  static const cardGreen = Color(0xFF66BB6A);

  // Фон изображений товаров
  static const productColors = [
    Color(0xFFBBDEFB),
    Color(0xFFFFE0B2),
    Color(0xFFC8E6C9),
    Color(0xFFF8BBD0),
    Color(0xFFD1C4E9),
    Color(0xFFB2EBF2),
  ];

  static const primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
