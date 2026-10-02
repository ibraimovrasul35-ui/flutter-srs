import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/constants/app_colors.dart';

/// Описание одного пункта нижней навигации.
class BottomBarItem {
  const BottomBarItem({
    required this.icon,
    required this.activeIcon,
    required this.labelKey,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData activeIcon;

  /// Ключ локализации для подписи.
  final String labelKey;

  /// Число на значке (0 — значок не показывается).
  final int badgeCount;
}

/// Переиспользуемый нижний бар: принимает любой список пунктов,
/// текущий индекс и обработчик нажатия.
class CustomBottomBar extends StatelessWidget {
  const CustomBottomBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<BottomBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12.r,
            offset: Offset(0, -2.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: colors.surface,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: colors.onSurfaceVariant,
          selectedFontSize: 12.sp,
          unselectedFontSize: 12.sp,
          iconSize: 24.sp,
          items: [
            for (final item in items)
              BottomNavigationBarItem(
                icon: _BadgeIcon(icon: item.icon, count: item.badgeCount),
                activeIcon: _BadgeIcon(
                  icon: item.activeIcon,
                  count: item.badgeCount,
                ),
                label: item.labelKey.tr(),
              ),
          ],
        ),
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({required this.icon, required this.count});

  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count', style: TextStyle(fontSize: 10.sp)),
      backgroundColor: AppColors.favorite,
      child: Icon(icon),
    );
  }
}
