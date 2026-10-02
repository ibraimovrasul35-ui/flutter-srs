import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../widgets/bottom_bar.dart';
import 'catalog_page.dart';
import 'favorites_page.dart';
import 'home_page.dart';
import 'profile_page.dart';

/// Каркас с нижней навигацией: переключает 4 страницы с анимацией.
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static const _catalogIndex = 1;

  int _currentIndex = 0;

  void _onTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return HomePage(onOpenCatalog: () => _onTap(_catalogIndex));
      case 1:
        return const CatalogPage();
      case 2:
        return FavoritesPage(onOpenCatalog: () => _onTap(_catalogIndex));
      default:
        return const ProfilePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Подписка на смену языка: при выборе другого языка страница
    // перестраивается и все тексты .tr() обновляются.
    context.locale;
    final favorites = AppScope.of(context).favorites;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _buildPage(_currentIndex),
        ),
      ),
      bottomNavigationBar: ValueListenableBuilder(
        valueListenable: favorites,
        builder: (context, ids, _) => CustomBottomBar(
          currentIndex: _currentIndex,
          onTap: _onTap,
          items: [
            const BottomBarItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              labelKey: 'home',
            ),
            const BottomBarItem(
              icon: Icons.shopping_bag_outlined,
              activeIcon: Icons.shopping_bag,
              labelKey: 'catalog',
            ),
            BottomBarItem(
              icon: Icons.favorite_border,
              activeIcon: Icons.favorite,
              labelKey: 'favorites',
              badgeCount: ids.length,
            ),
            const BottomBarItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              labelKey: 'profile',
            ),
          ],
        ),
      ),
    );
  }
}
