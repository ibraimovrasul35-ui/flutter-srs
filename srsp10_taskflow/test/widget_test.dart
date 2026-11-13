import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srsp10_taskflow/app.dart';
import 'package:srsp10_taskflow/data/database/app_database.dart';
import 'package:srsp10_taskflow/data/seed/demo_seeder.dart';

void main() {
  testWidgets('главный экран показывает проекты из базы и вкладки', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() => DemoSeeder(db).seedIfEmpty());

    await tester.pumpWidget(TaskFlowApp(database: db));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();

    expect(find.text('Интернет-магазин'), findsOneWidget);
    expect(find.text('Дипломная работа'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('Люди'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    expect(find.textContaining('Амина'), findsWidgets);

    // Drift снимает подписки watch() через таймеры fake-async зоны теста —
    // их нужно прокачать, иначе db.close() ждёт бесконечно.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(db.close);
  });
}
