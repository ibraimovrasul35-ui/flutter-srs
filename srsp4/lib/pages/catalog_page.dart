import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/app_scope.dart';
import '../core/constants/app_text_styles.dart';
import '../data/demo_products.dart';
import '../data/product.dart';
import '../widgets/product_card.dart';

class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});

  /// Количество колонок зависит от реальной ширины экрана (MediaQuery):
  /// ScreenUtil масштабирует размеры, но не меняет раскладку,
  /// поэтому на планшете и в горизонтальной ориентации колонок больше.
  int _columns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  void _toggle(BuildContext context, Product product) {
    final added = AppScope.of(context).favorites.toggle(product);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            (added ? 'added_to_favorites' : 'removed_from_favorites').tr(),
            style: AppTextStyles.caption.copyWith(
              color: Theme.of(context).colorScheme.onInverseSurface,
            ),
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = AppScope.of(context).favorites;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('catalog'.tr(), style: AppTextStyles.headline),
                SizedBox(height: 4.h),
                Text('catalog_subtitle'.tr(), style: AppTextStyles.caption),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: favorites,
              builder: (context, ids, _) => GridView.builder(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _columns(context),
                  mainAxisSpacing: 12.h,
                  crossAxisSpacing: 12.w,
                  childAspectRatio: 0.72,
                ),
                itemCount: demoProducts.length,
                itemBuilder: (context, index) {
                  final product = demoProducts[index];
                  return ProductCard(
                    product: product,
                    colorIndex: index,
                    isFavorite: ids.contains(product.id),
                    onFavoriteTap: () => _toggle(context, product),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
