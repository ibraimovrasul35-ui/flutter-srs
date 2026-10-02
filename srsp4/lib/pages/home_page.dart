import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/app_scope.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../data/demo_products.dart';
import '../widgets/info_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onOpenCatalog});

  /// Переход на вкладку «Каталог».
  final VoidCallback onOpenCatalog;

  @override
  Widget build(BuildContext context) {
    final favorites = AppScope.of(context).favorites;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        children: [
          // Заголовок
          Text('home'.tr(), style: AppTextStyles.headline),
          SizedBox(height: 16.h),

          // Приветственный баннер с иконкой
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'hello'.tr(args: ['user_name'.tr().split(' ').first]),
                        style: AppTextStyles.onPrimaryTitle,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'welcome_title'.tr(),
                        style: AppTextStyles.bodyBold.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'welcome_text'.tr(),
                        style: AppTextStyles.onPrimaryBody,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Container(
                  width: 72.w,
                  height: 72.w,
                  decoration: const BoxDecoration(
                    color: AppColors.whiteTransparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.storefront,
                    color: AppColors.white,
                    size: 40.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Статистика
          ValueListenableBuilder(
            valueListenable: favorites,
            builder: (context, ids, _) => Row(
              children: [
                Expanded(
                  child: _StatTile(
                    value: '${demoProducts.length}',
                    label: 'stats_products'.tr(),
                    icon: Icons.inventory_2_outlined,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _StatTile(
                    value: '${ids.length}',
                    label: 'stats_favorites'.tr(),
                    icon: Icons.favorite_border,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Карточки
          InfoCard(
            icon: Icons.new_releases_outlined,
            title: 'card_new_title'.tr(),
            text: 'card_new_text'.tr(),
            color: AppColors.cardBlue,
          ),
          SizedBox(height: 12.h),
          InfoCard(
            icon: Icons.local_offer_outlined,
            title: 'card_sale_title'.tr(),
            text: 'card_sale_text'.tr(),
            color: AppColors.cardOrange,
          ),
          SizedBox(height: 12.h),
          InfoCard(
            icon: Icons.local_shipping_outlined,
            title: 'card_delivery_title'.tr(),
            text: 'card_delivery_text'.tr(),
            color: AppColors.cardGreen,
          ),
          SizedBox(height: 20.h),

          SizedBox(
            height: 50.h,
            child: FilledButton.icon(
              onPressed: onOpenCatalog,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              icon: Icon(Icons.shopping_bag_outlined, size: 20.sp),
              label: Text('go_to_catalog'.tr(), style: AppTextStyles.button),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(14.r),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 28.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: AppTextStyles.title),
                  Text(
                    label,
                    style: AppTextStyles.small,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
