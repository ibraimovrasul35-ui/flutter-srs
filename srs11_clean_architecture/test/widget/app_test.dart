import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srs11_clean_architecture/core/di/injection.dart';
import 'package:srs11_clean_architecture/core/rest_client/dio_client.dart';
import 'package:srs11_clean_architecture/main.dart';

/// Приложение целиком: настоящий DI, mock только у Dio и SharedPreferences.
void main() {
  late DioAdapter adapter;

  final posts = List.generate(
      10,
      (i) => {
            'id': i + 1,
            'userId': 1,
            'title': 'Заголовок ${i + 1}',
            'body': 'Текст ${i + 1}',
          });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final dio = DioClient.create(enableLogging: false);
    adapter = DioAdapter(dio: dio);
    adapter.onGet('/users', (s) => s.reply(200, [
          {'id': 1, 'name': 'Leanne Graham'},
        ]));
    await initDependencies(
        prefs: await SharedPreferences.getInstance(), dio: dio);
  });

  testWidgets('Error → «Повторить» → Success', (tester) async {
    adapter.onGet('/posts', (s) => s.reply(500, {'trace': 'NullPointer at X'}),
        queryParameters: {'_page': 1, '_limit': 10});

    await tester.pumpWidget(const PostExplorerApp());
    await tester.pumpAndSettle();

    expect(find.text('На сервере произошла ошибка. Попробуйте позже'),
        findsOneWidget);
    expect(find.textContaining('NullPointer'), findsNothing); // сырой текст скрыт
    expect(find.textContaining('500'), findsNothing);

    adapter.onGet('/posts', (s) => s.reply(200, posts),
        queryParameters: {'_page': 1, '_limit': 10});
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();

    expect(find.text('Заголовок 1'), findsOneWidget);
    expect(find.text('Leanne Graham'), findsWidgets);
  });

  testWidgets('Избранное: добавить звёздочкой и увидеть на экране избранного',
      (tester) async {
    adapter.onGet('/posts', (s) => s.reply(200, posts),
        queryParameters: {'_page': 1, '_limit': 10});

    await tester.pumpWidget(const PostExplorerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Избранное'));
    await tester.pumpAndSettle();
    expect(find.textContaining('В избранном пока пусто'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('В избранное').first);
    await tester.pumpAndSettle();
    expect(find.text('Добавлено в избранное'), findsOneWidget);

    await tester.tap(find.byTooltip('Избранное'));
    await tester.pumpAndSettle();
    expect(find.text('Заголовок 1'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);
  });
}
