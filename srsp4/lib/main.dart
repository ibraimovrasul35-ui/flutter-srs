import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_scope.dart';
import 'core/localization/app_locales.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'data/favorites_controller.dart';
import 'pages/main_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    // Выбранный язык easy_localization сохраняет сам (saveLocale: true).
    EasyLocalization(
      supportedLocales: AppLocales.supported,
      path: AppLocales.path,
      fallbackLocale: AppLocales.fallback,
      useOnlyLangCode: true,
      child: AppScope(
        theme: ThemeController(prefs),
        favorites: FavoritesController(prefs),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Размер макета, от которого ScreenUtil считает .w / .h / .sp / .r
  static const designSize = Size(375, 812);

  @override
  Widget build(BuildContext context) {
    final theme = AppScope.of(context).theme;

    return ScreenUtilInit(
      designSize: designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => ValueListenableBuilder(
        valueListenable: theme,
        builder: (context, themeMode, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (_) => 'app_title'.tr(),
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          themeAnimationDuration: const Duration(milliseconds: 300),
          home: child,
        ),
      ),
      child: const MainPage(),
    );
  }
}
