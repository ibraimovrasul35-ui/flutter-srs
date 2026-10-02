import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../data/product.dart';
import 'product_image.dart';

/// Карточка товара для GridView в каталоге.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.colorIndex,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  final Product product;
  final int colorIndex;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ProductImage(product: product, colorIndex: colorIndex),
                ),
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: _FavoriteButton(
                    isFavorite: isFavorite,
                    onTap: onFavoriteTap,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.nameKey.tr(),
                  style: AppTextStyles.bodyBold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  'price'.tr(args: [formatPrice(product.price)]),
                  style: AppTextStyles.price,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, required this.onTap});

  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(6.r),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              key: ValueKey(isFavorite),
              color: AppColors.favorite,
              size: 22.sp,
            ),
          ),
        ),
      ),
    );
  }
}

/// 24990 -> "24 990"
String formatPrice(int price) {
  final digits = price.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
