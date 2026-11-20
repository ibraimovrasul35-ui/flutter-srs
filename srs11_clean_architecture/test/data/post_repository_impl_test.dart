import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srs11_clean_architecture/core/rest_client/dio_client.dart';
import 'package:srs11_clean_architecture/core/rest_client/rest_client.dart';
import 'package:srs11_clean_architecture/src/data/datasources/json_storage.dart';
import 'package:srs11_clean_architecture/src/data/datasources/post_local_data_source.dart';
import 'package:srs11_clean_architecture/src/data/datasources/post_remote_data_source.dart';
import 'package:srs11_clean_architecture/src/data/repositories/post_repository_impl.dart';
import 'package:srs11_clean_architecture/src/domain/entities/post.dart';
import 'package:srs11_clean_architecture/src/domain/failures/failures.dart';

/// Все запросы обслуживает mock-адаптер Dio, интернет не нужен.
/// Проверяется вся цепочка: RestClient → RemoteDataSource (исключения)
/// → RepositoryImpl (Failure) + LocalDataSource (кэш).
void main() {
  late DioAdapter adapter;
  late PostRepositoryImpl repository;

  const page1 = {'_page': 1, '_limit': 10};

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
    final prefs = await SharedPreferences.getInstance();
    final dio = DioClient.create(enableLogging: false);
    adapter = DioAdapter(dio: dio);
    repository = PostRepositoryImpl(
      remote: PostRemoteDataSourceImpl(RestClient(dio)),
      local: PostLocalDataSourceImpl(JsonStorage(prefs)),
    );
  });

  Future<Failure> failureOf(Future<dynamic> call) async {
    final result = await call;
    return result.getLeft().toNullable() as Failure;
  }

  test('успех: страница → сущности Post и сохранение в кэш', () async {
    adapter.onGet('/posts', (s) => s.reply(200, postsJson(1, 10)),
        queryParameters: page1);

    final result = await repository.getPosts(page: 1, limit: 10);

    final posts = result.getOrElse((_) => []);
    expect(posts, hasLength(10));
    expect(posts.first, isA<Post>());
    final cached = (await repository.getCachedPosts()).getOrElse((_) => null);
    expect(cached?.data, posts);
  });

  test('пустой ответ → Right([]) (Empty State, а не ошибка)', () async {
    adapter.onGet('/posts', (s) => s.reply(200, <dynamic>[]),
        queryParameters: page1);

    final result = await repository.getPosts(page: 1, limit: 10);

    expect(result.isRight(), isTrue);
    expect(result.getOrElse((_) => [const Post(id: 0, userId: 0, title: '', body: '')]),
        isEmpty);
  });

  test('500 → ServerFailure', () async {
    adapter.onGet('/posts', (s) => s.reply(500, {'message': 'Internal'}),
        queryParameters: page1);

    expect(await failureOf(repository.getPosts(page: 1, limit: 10)),
        isA<ServerFailure>());
  });

  test('503 → ServerFailure', () async {
    adapter.onGet('/posts/1', (s) => s.reply(503, {}));
    adapter.onGet('/posts/1/comments', (s) => s.reply(200, <dynamic>[]));

    expect(await failureOf(repository.getPostDetails(1)), isA<ServerFailure>());
  });

  test('401 → UnauthorizedFailure', () async {
    adapter.onGet('/posts', (s) => s.reply(401, {'error': 'token expired'}),
        queryParameters: page1);

    expect(await failureOf(repository.getPosts(page: 1, limit: 10)),
        isA<UnauthorizedFailure>());
  });

  test('400 → ValidationFailure', () async {
    const body = {'title': 'Мой пост', 'body': 'Текст моего поста', 'userId': 3};
    adapter.onPost('/posts', (s) => s.reply(400, {'error': 'bad'}), data: body);

    expect(
        await failureOf(repository.createPost(
            title: 'Мой пост', body: 'Текст моего поста', userId: 3)),
        isA<ValidationFailure>());
  });

  test('404 и прочие коды → UnknownFailure', () async {
    adapter.onGet('/posts/999', (s) => s.reply(404, {}));
    adapter.onGet('/posts/999/comments', (s) => s.reply(404, {}));

    expect(await failureOf(repository.getPostDetails(999)),
        isA<UnknownFailure>());
  });

  test('нет интернета → NetworkFailure, текст без технических деталей, '
      'кэш не удаляется', () async {
    adapter.onGet('/posts', (s) => s.reply(200, postsJson(1, 10)),
        queryParameters: page1);
    await repository.getPosts(page: 1, limit: 10);

    adapter.onGet(
      '/posts',
      (s) => s.throws(
        0,
        DioException.connectionError(
          requestOptions: RequestOptions(path: '/posts'),
          reason: 'SocketException: Failed host lookup',
        ),
      ),
      queryParameters: page1,
    );

    final failure = await failureOf(repository.getPosts(page: 1, limit: 10));
    expect(failure, isA<NetworkFailure>());
    expect(failure.message, isNot(contains('Socket')));
    expect(failure.message, isNot(contains('Dio')));
    final cached = (await repository.getCachedPosts()).getOrElse((_) => null);
    expect(cached?.data, hasLength(10));
  });

  test('таймаут → NetworkFailure', () async {
    adapter.onGet(
      '/posts',
      (s) => s.throws(
        0,
        DioException.connectionTimeout(
          requestOptions: RequestOptions(path: '/posts'),
          timeout: const Duration(seconds: 10),
        ),
      ),
      queryParameters: page1,
    );

    final failure = await failureOf(repository.getPosts(page: 1, limit: 10));
    expect(failure, const NetworkFailure.timeout());
  });

  test('некорректный JSON → UnknownFailure с понятным текстом', () async {
    adapter.onGet(
      '/posts',
      (s) => s.reply(200, [
        {'id': 'oops', 'title': null},
      ]),
      queryParameters: page1,
    );

    final failure = await failureOf(repository.getPosts(page: 1, limit: 10));
    expect(failure, isA<UnknownFailure>());
    expect(failure.message, contains('неожиданном формате'));
  });

  test('фильтр по автору: GET /posts?userId=, отдельный кэш', () async {
    adapter.onGet('/posts', (s) => s.reply(200, postsJson(11, 10, userId: 2)),
        queryParameters: {'userId': 2, '_page': 1, '_limit': 10});

    final result = await repository.getPosts(page: 1, limit: 10, userId: 2);

    expect(result.getOrElse((_) => []).every((p) => p.userId == 2), isTrue);
    expect((await repository.getCachedPosts(userId: 2)).getOrElse((_) => null),
        isNotNull);
    expect((await repository.getCachedPosts()).getOrElse((_) => null), isNull);
  });

  test('следующие страницы дописываются в кэш без дубликатов', () async {
    adapter
      ..onGet('/posts', (s) => s.reply(200, postsJson(1, 10)),
          queryParameters: page1)
      ..onGet('/posts', (s) => s.reply(200, postsJson(10, 10)),
          queryParameters: {'_page': 2, '_limit': 10});

    await repository.getPosts(page: 1, limit: 10);
    await repository.getPosts(page: 2, limit: 10);

    final cached = (await repository.getCachedPosts()).getOrElse((_) => null)!;
    expect(cached.data.map((p) => p.id), List.generate(19, (i) => i + 1));
  });

  test('детали: пост + комментарии, затем доступны из кэша', () async {
    adapter
      ..onGet('/posts/1', (s) => s.reply(200, postsJson(1, 1).first))
      ..onGet(
          '/posts/1/comments',
          (s) => s.reply(200, [
                {'id': 1, 'postId': 1, 'name': 'n', 'body': 'b'},
              ]));

    final details =
        (await repository.getPostDetails(1)).getOrElse((_) => throw 'fail');
    expect(details.comments.single.email, isNull);

    final cached =
        (await repository.getCachedPostDetails(1)).getOrElse((_) => null);
    expect(cached?.data, details);
  });

  test('POST /posts и сохранение локального поста', () async {
    const body = {'title': 'Мой пост', 'body': 'Текст моего поста', 'userId': 3};
    adapter.onPost('/posts', (s) => s.reply(201, {...body, 'id': 101}),
        data: body);

    final created = (await repository.createPost(
            title: 'Мой пост', body: 'Текст моего поста', userId: 3))
        .getOrElse((_) => throw 'fail');
    expect(created.id, 101);

    final local =
        (await repository.saveLocalPost(created)).getOrElse((_) => throw 'fail');
    expect(local.isLocal, isTrue);
    expect(local.id, isNegative);
    final saved = (await repository.getLocalPosts()).getOrElse((_) => []);
    expect(saved.single.title, 'Мой пост');
    expect(saved.single.isLocal, isTrue);
  });
}
