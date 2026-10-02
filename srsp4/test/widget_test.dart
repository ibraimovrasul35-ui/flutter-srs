import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:srsp4/core/app_scope.dart';
import 'package:srsp4/core/localization/app_locales.dart';
import 'package:srsp4/core/theme/theme_controller.dart';
import 'package:srsp4/data/favorites_controller.dart';
import 'package:srsp4/main.dart';

/// В тестах читаем переводы с диска синхронно — так они гарантированно
/// загружаются в каждом тесте, а не только в первом.
class _FileAssetLoader extends AssetLoader {
  const _FileAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final file = File('$path/${locale.languageCode}.json');
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }
}

Future<void> pumpApp(WidgetTester tester) async {
  // Экран обычного телефона: 393 x 852 логических пикселей.
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  EasyLocalization.logger.enableBuildModes = [];
  await EasyLocalization.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: AppLocales.supported,
      path: AppLocales.path,
      fallbackLocale: AppLocales.fallback,
      startLocale: AppLocales.en,
      saveLocale: false,
      useOnlyLangCode: true,
      assetLoader: const _FileAssetLoader(),
      child: AppScope(
        theme: ThemeController(prefs),
        favorites: FavoritesController(prefs),
        child: const MyApp(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('app shows main navigation labels in English', (tester) async {
    await pumpApp(tester);

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Catalog'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('bottom bar switches pages and favorites work', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Catalog'));
    await tester.pumpAndSettle();
    expect(find.text('Wireless headphones'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_border).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    expect(find.text('Wireless headphones'), findsOneWidget);
    expect(find.text('Items: 1'), findsOneWidget);
  });

  testWidgets('language can be switched on profile page', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Русский'));
    await tester.pumpAndSettle();

    expect(find.text('Главная'), findsOneWidget);
    expect(find.text('Настройки'), findsOneWidget);
  });
}
