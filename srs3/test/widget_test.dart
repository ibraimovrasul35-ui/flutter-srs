import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:srs3/main.dart';

void main() {
  testWidgets('App shows main screen with tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Мое приложение'), findsOneWidget);
    expect(find.text('Список'), findsOneWidget);
    expect(find.text('Сетка'), findsOneWidget);
    expect(find.byType(Drawer), findsOneWidget);
  });
}
