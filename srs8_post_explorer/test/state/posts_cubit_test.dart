import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:srs8_post_explorer/core/error/app_exception.dart';
import 'package:srs8_post_explorer/data/local/post_cache.dart';
import 'package:srs8_post_explorer/data/models/post.dart';
import 'package:srs8_post_explorer/data/repositories/post_repository.dart';
import 'package:srs8_post_explorer/presentation/state/posts_cubit.dart';

class MockPostRepository extends Mock implements PostRepository {}

List<Post> makePosts(int from, int count, {int userId = 1}) => List.generate(
    count,
    (i) => Post(
        id: from + i, userId: userId, title: 'post ${from + i}', body: 'b'));

void main() {
  late MockPostRepository repository;
  late PostsCubit cubit;

  setUp(() {
    repository = MockPostRepository();
    when(() => repository.getLocalPosts()).thenReturn([]);
    when(() => repository.getCachedUsers()).thenReturn(null);
    when(() => repository.fetchUsers()).thenAnswer((_) async => []);
    when(() => repository.getCachedPosts(userId: any(named: 'userId')))
        .thenReturn(null);
    when(() => repository.fetchPosts(
          page: 1,
          userId: null,
          cancelToken: any(named: 'cancelToken'),
        )).thenAnswer((_) async => makePosts(1, 10));
    cubit = PostsCubit(repository);
  });

  tearDown(() => cubit.close());

  // Тест 6
  test('одна и та же страница не загружается дважды', () async {
    await cubit.init();
    expect(cubit.state.posts, hasLength(10));

    final page2 = Completer<List<Post>>();
    when(() => repository.fetchPosts(
          page: 2,
          userId: null,
          cancelToken: any(named: 'cancelToken'),
        )).thenAnswer((_) => page2.future);

    // Пользователь быстро прокручивает — вызовов много, запрос должен быть один.
    final first = cubit.loadNextPage();
    unawaited(cubit.loadNextPage());
    unawaited(cubit.loadNextPage());
    expect(cubit.state.isLoadingMore, isTrue);

    page2.complete(makePosts(11, 10));
    await first;

    verify(() => repository.fetchPosts(
          page: 2,
          userId: null,
          cancelToken: any(named: 'cancelToken'),
        )).called(1);
    expect(cubit.state.posts, hasLength(20));
    expect(cubit.state.page, 2);
    expect(cubit.state.isLoadingMore, isFalse);
  });

  test('после смены фильтра старые результаты не смешиваются с новыми',
      () async {
    await cubit.init();

    // Запрос страницы 2 «всех постов» зависнет и ответит уже после смены фильтра.
    final slowPage2 = Completer<List<Post>>();
    when(() => repository.fetchPosts(
          page: 2,
          userId: null,
          cancelToken: any(named: 'cancelToken'),
        )).thenAnswer((_) => slowPage2.future);
    when(() => repository.fetchPosts(
          page: 1,
          userId: 5,
          cancelToken: any(named: 'cancelToken'),
        )).thenAnswer((_) async => makePosts(41, 10, userId: 5));

    final staleRequest = cubit.loadNextPage();
    await cubit.selectAuthor(5);
    slowPage2.complete(makePosts(11, 10)); // ответ старого запроса
    await staleRequest;

    expect(cubit.state.selectedUserId, 5);
    expect(cubit.state.page, 1);
    expect(cubit.state.posts, hasLength(10));
    expect(cubit.state.posts.every((p) => p.userId == 5), isTrue);
  });

  test('ошибка при подгрузке страницы не стирает список, можно повторить',
      () async {
    await cubit.init();
    when(() => repository.fetchPosts(
          page: 2,
          userId: null,
          cancelToken: any(named: 'cancelToken'),
        )).thenThrow(const AppException(AppErrorType.timeout));

    await cubit.loadNextPage();

    expect(cubit.state.posts, hasLength(10));
    expect(cubit.state.loadMoreError, isNotNull);
    expect(cubit.state.page, 1);
  });

  test('кэш показывается сразу, при ошибке сети остаётся на экране', () async {
    when(() => repository.getCachedPosts(userId: null))
        .thenReturn(Cached(makePosts(1, 10), DateTime(2026, 10, 1)));
    when(() => repository.fetchPosts(
          page: 1,
          userId: null,
          cancelToken: any(named: 'cancelToken'),
        )).thenThrow(const AppException(AppErrorType.noConnection));

    await cubit.init();

    expect(cubit.state.status, ListStatus.success);
    expect(cubit.state.posts, hasLength(10));
    expect(cubit.state.isFromCache, isTrue);
    expect(cubit.state.errorMessage, 'Нет подключения к интернету');
  });
}
