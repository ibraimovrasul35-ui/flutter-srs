import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_colors.dart';

/// Текстовые стили приложения.
///
/// Объявлены через геттеры, чтобы .sp пересчитывался после инициализации
/// ScreenUtil и при повороте экрана. Если цвет не указан, он берётся из темы,
/// поэтому стили работают и в светлой, и в тёмной теме.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get headline =>
      TextStyle(fontSize: 26.sp, fontWeight: FontWeight.bold);

  static TextStyle get title =>
      TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold);

  static TextStyle get subtitle =>
      TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600);

  static TextStyle get body => TextStyle(fontSize: 16.sp);

  static TextStyle get bodyBold =>
      TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600);

  static TextStyle get caption =>
      TextStyle(fontSize: 14.sp, color: AppColors.textSecondary);

  static TextStyle get small =>
      TextStyle(fontSize: 12.sp, color: AppColors.textSecondary);

  static TextStyle get price => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  static TextStyle get button => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  static TextStyle get onPrimaryTitle => TextStyle(
    fontSize: 22.sp,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  static TextStyle get onPrimaryBody =>
      TextStyle(fontSize: 14.sp, color: AppColors.white);
}
