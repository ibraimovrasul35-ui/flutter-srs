import 'package:flutter_test/flutter_test.dart';

import 'package:srs2bezfoto/main.dart';

void main() {
  testWidgets('Layout shows expected texts', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Lab 3: Layout Basics'), findsOneWidget);
    expect(find.text('Welcome to Flutter!'), findsOneWidget);
    expect(find.text('Left Text'), findsOneWidget);
    expect(find.text('Right Text'), findsOneWidget);
  });
}
