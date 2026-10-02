import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:srs1_flutter/main.dart';

void main() {
  testWidgets('Главный экран показывает тексты в контейнерах', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Первое Flutter-приложение'), findsOneWidget);
    expect(find.text('Привет, Flutter!'), findsOneWidget);
    expect(find.byType(Container), findsAtLeastNWidgets(2));
  });
}
