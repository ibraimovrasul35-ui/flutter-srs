import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

/// Цветная карточка с иконкой, заголовком и текстом (главная страница).
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: AppColors.whiteTransparent,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(icon, color: AppColors.white, size: 28.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyBold.copyWith(
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(text, style: AppTextStyles.onPrimaryBody),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
