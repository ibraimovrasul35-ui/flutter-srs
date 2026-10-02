import 'package:flutter/widgets.dart';

import '../data/favorites_controller.dart';
import 'theme/theme_controller.dart';

/// Даёт страницам доступ к контроллерам темы и избранного
/// без сторонних пакетов управления состоянием.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.theme,
    required this.favorites,
    required super.child,
  });

  final ThemeController theme;
  final FavoritesController favorites;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope не найден в дереве виджетов');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      theme != oldWidget.theme || favorites != oldWidget.favorites;
}
