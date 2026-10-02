import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:srsp5/main.dart';

void main() {
  testWidgets('Registration form shows errors on empty submit',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp());

    expect(find.text('Register Form'), findsOneWidget);

    await tester.tap(find.text('Submit Form'));
    await tester.pump();

    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });
}
