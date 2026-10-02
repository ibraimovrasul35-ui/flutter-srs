import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/constants/app_colors.dart';
import '../data/product.dart';

/// Картинка товара из сети. Пока грузится или если нет интернета,
/// показывается иконка товара на цветном фоне.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.product,
    required this.colorIndex,
    this.iconSize,
  });

  final Product product;
  final int colorIndex;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color:
          AppColors.productColors[colorIndex % AppColors.productColors.length],
      alignment: Alignment.center,
      child: Icon(
        product.icon,
        size: iconSize ?? 48.sp,
        color: AppColors.primaryDark,
      ),
    );

    return Image.network(
      product.imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : placeholder,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}
