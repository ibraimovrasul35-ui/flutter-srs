import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srs8_post_explorer/core/error/app_exception.dart';
import 'package:srs8_post_explorer/core/network/dio_client.dart';
import 'package:srs8_post_explorer/data/local/post_cache.dart';
import 'package:srs8_post_explorer/data/remote/post_api.dart';
import 'package:srs8_post_explorer/data/repositories/post_repository.dart';

/// Все запросы обслуживает mock-адаптер Dio — тесты не зависят от интернета.
void main() {
  late DioAdapter adapter;
  late PostRepository repository;
  late PostCache cache;

  List<Map<String, dynamic>> postsJson(int from, int count, {int userId = 1}) =>
      List.generate(
          count,
          (i) => {
                'id': from + i,
                'userId': userId,
                'title': 'post ${from + i}',
                'body': 'body ${from + i}',
              });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    cache = PostCache(await SharedPreferences.getInstance());
    final dio = DioClient.create(enableLogging: false);
    adapter = DioAdapter(dio: dio);
    repository = PostRepository(api: PostApi(dio), cache: cache);
  });

  // Тест 3
  test('успешно загружает страницу постов и сохраняет её в кэш', () async {
    adapter.onGet(
      '/posts',
      (server) => server.reply(200, postsJson(1, 10)),
      queryParameters: {'_page': 1, '_limit': 10},
    );

    final posts = await repository.fetchPosts(page: 1);

    expect(posts, hasLength(10));
    expect(posts.first.id, 1);
    expect(repository.getCachedPosts()?.data, posts);
  });

  // Тест 4
  test('ошибка сервера 500 превращается в AppException(server)', () async {
    adapter.onGet(
      '/posts',
      (server) => server.reply(500, {'message': 'Internal Server Error'}),
      queryParameters: {'_page': 1, '_limit': 10},
    );

    await expectLater(
      repository.fetchPosts(page: 1),
      throwsA(isA<AppException>()
          .having((e) => e.type, 'type', AppErrorType.server)
          .having((e) => e.statusCode, 'statusCode', 500)),
    );
  });

  test('ошибка 404 -> AppException(client)', () async {
    adapter.onGet('/posts/999', (server) => server.reply(404, {}));

    await expectLater(
      repository.fetchPost(999),
      throwsA(isA<AppException>()
          .having((e) => e.type, 'type', AppErrorType.client)
          .having((e) => e.message, 'message', contains('404'))),
    );
  });

  test('нет сети: ошибка noConnection, старый кэш не удаляется', () async {
    adapter.onGet(
      '/posts',
      (server) => server.reply(200, postsJson(1, 10)),
      queryParameters: {'_page': 1, '_limit': 10},
    );
    await repository.fetchPosts(page: 1);

    adapter.onGet(
      '/posts',
      (server) => server.throws(
        0,
        DioException.connectionError(
          requestOptions: RequestOptions(path: '/posts'),
          reason: 'SocketException: Failed host lookup',
        ),
      ),
      queryParameters: {'_page': 1, '_limit': 10},
    );

    await expectLater(
      repository.fetchPosts(page: 1),
      throwsA(isA<AppException>()
          .having((e) => e.type, 'type', AppErrorType.noConnection)),
    );
    expect(repository.getCachedPosts()?.data, hasLength(10));
  });

  test('некорректный JSON от сервера -> AppException(parsing)', () async {
    adapter.onGet(
      '/posts',
      (server) => server.reply(200, [
        {'id': 'oops', 'title': null},
      ]),
      queryParameters: {'_page': 1, '_limit': 10},
    );

    await expectLater(
      repository.fetchPosts(page: 1),
      throwsA(isA<AppException>()
          .having((e) => e.type, 'type', AppErrorType.parsing)),
    );
  });

  test('фильтр по автору вызывает GET /posts?userId=', () async {
    adapter.onGet(
      '/posts',
      (server) => server.reply(200, postsJson(11, 10, userId: 2)),
      queryParameters: {'userId': 2, '_page': 1, '_limit': 10},
    );

    final posts = await repository.fetchPosts(page: 1, userId: 2);

    expect(posts.every((p) => p.userId == 2), isTrue);
    // Кэш для разных фильтров хранится отдельно.
    expect(repository.getCachedPosts(userId: 2)?.data, hasLength(10));
    expect(repository.getCachedPosts(), isNull);
  });

  test('следующие страницы дописываются в кэш без дубликатов', () async {
    adapter
      ..onGet('/posts', (s) => s.reply(200, postsJson(1, 10)),
          queryParameters: {'_page': 1, '_limit': 10})
      ..onGet('/posts', (s) => s.reply(200, postsJson(10, 10)),
          queryParameters: {'_page': 2, '_limit': 10});

    await repository.fetchPosts(page: 1);
    await repository.fetchPosts(page: 2);

    final ids = repository.getCachedPosts()!.data.map((p) => p.id).toList();
    expect(ids, List.generate(19, (i) => i + 1));
  });

  // Доп.: POST через mock-адаптер Dio
  test('POST /posts отправляет данные и возвращает объект сервера', () async {
    final request = {
      'title': 'Мой пост',
      'body': 'Текст моего поста',
      'userId': 3,
    };
    adapter.onPost(
      '/posts',
      (server) => server.reply(201, {...request, 'id': 101}),
      data: request,
    );

    final created = await repository.createPost(
        title: 'Мой пост', body: 'Текст моего поста', userId: 3);
    expect(created.id, 101);
    expect(created.title, 'Мой пост');

    final local = await repository.saveLocalPost(created);
    expect(local.isLocal, isTrue);
    expect(local.id, isNegative);
    expect(repository.getLocalPosts().single.title, 'Мой пост');
  });
}
