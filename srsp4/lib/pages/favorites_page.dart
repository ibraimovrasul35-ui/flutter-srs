import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/app_scope.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../data/demo_products.dart';
import '../data/favorites_controller.dart';
import '../data/product.dart';
import '../widgets/product_card.dart';
import '../widgets/product_image.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key, required this.onOpenCatalog});

  /// Переход на вкладку «Каталог» из пустого состояния.
  final VoidCallback onOpenCatalog;

  @override
  Widget build(BuildContext context) {
    final favorites = AppScope.of(context).favorites;

    return SafeArea(
      bottom: false,
      child: ValueListenableBuilder(
        valueListenable: favorites,
        builder: (context, ids, _) {
          final products = favorites.products;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 8.w, 12.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'favorites'.tr(),
                        style: AppTextStyles.headline,
                      ),
                    ),
                    if (products.isNotEmpty)
                      TextButton.icon(
                        onPressed: favorites.clear,
                        icon: Icon(Icons.delete_outline, size: 20.sp),
                        label: Text(
                          'clear_all'.tr(),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.favorite,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.favorite,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: products.isEmpty
                    ? _EmptyState(onOpenCatalog: onOpenCatalog)
                    : _FavoritesList(products: products, favorites: favorites),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FavoritesList extends StatelessWidget {
  const _FavoritesList({required this.products, required this.favorites});

  final List<Product> products;
  final FavoritesController favorites;

  @override
  Widget build(BuildContext context) {
    // Итог — последний элемент списка, чтобы всё прокручивалось
    // и в горизонтальной ориентации.
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      itemCount: products.length + 1,
      separatorBuilder: (_, _) => SizedBox(height: 10.h),
      itemBuilder: (context, index) {
        if (index == products.length) {
          return _TotalCard(
            count: products.length,
            total: favorites.totalPrice,
          );
        }
        final product = products[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.all(10.r),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: SizedBox(
                    width: 72.w,
                    height: 72.w,
                    child: ProductImage(
                      product: product,
                      colorIndex: demoProducts.indexOf(product),
                      iconSize: 32.sp,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.nameKey.tr(),
                        style: AppTextStyles.bodyBold,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'price'.tr(args: [formatPrice(product.price)]),
                        style: AppTextStyles.price,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => favorites.toggle(product),
                  icon: Icon(
                    Icons.favorite,
                    color: AppColors.favorite,
                    size: 24.sp,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.count, required this.total});

  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              'favorites_count'.tr(args: ['$count']),
              style: AppTextStyles.onPrimaryBody,
            ),
          ),
          SizedBox(width: 12.w),
          Flexible(
            child: Text(
              'favorites_total'.tr(args: [formatPrice(total)]),
              style: AppTextStyles.bodyBold.copyWith(color: AppColors.white),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onOpenCatalog});

  final VoidCallback onOpenCatalog;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110.w,
              height: 110.w,
              decoration: BoxDecoration(
                color: AppColors.favorite.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border,
                size: 56.sp,
                color: AppColors.favorite,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'favorites_empty_title'.tr(),
              style: AppTextStyles.subtitle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'favorites_empty_text'.tr(),
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            FilledButton(
              onPressed: onOpenCatalog,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text('go_to_catalog'.tr(), style: AppTextStyles.button),
            ),
          ],
        ),
      ),
    );
  }
}
