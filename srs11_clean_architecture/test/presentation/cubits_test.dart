import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:srs11_clean_architecture/src/domain/entities/author.dart';
import 'package:srs11_clean_architecture/src/domain/entities/post.dart';
import 'package:srs11_clean_architecture/src/domain/failures/failures.dart';
import 'package:srs11_clean_architecture/src/domain/usecases/favorites_usecases.dart';
import 'package:srs11_clean_architecture/src/domain/usecases/filter_posts_usecase.dart';
import 'package:srs11_clean_architecture/src/domain/usecases/get_authors_usecase.dart';
import 'package:srs11_clean_architecture/src/domain/usecases/get_cached_posts_usecase.dart';
import 'package:srs11_clean_architecture/src/domain/usecases/get_posts_usecase.dart';
import 'package:srs11_clean_architecture/src/domain/usecases/local_posts_usecases.dart';
import 'package:srs11_clean_architecture/src/domain/usecases/usecase.dart';
import 'package:srs11_clean_architecture/src/presentation/bloc/favorites/favorites_cubit.dart';
import 'package:srs11_clean_architecture/src/presentation/bloc/posts/posts_cubit.dart';

class MockGetPosts extends Mock implements GetPostsUseCase {}

class MockGetCachedPosts extends Mock implements GetCachedPostsUseCase {}

class MockGetAuthors extends Mock implements GetAuthorsUseCase {}

class MockGetLocalPosts extends Mock implements GetLocalPostsUseCase {}

class MockSaveLocalPost extends Mock implements SaveLocalPostUseCase {}

class MockGetFavorites extends Mock implements GetFavoritesUseCase {}

class MockToggleFavorite extends Mock implements ToggleFavoriteUseCase {}

List<Post> makePosts(int from, int count, {int userId = 1}) => List.generate(
    count,
    (i) =>
        Post(id: from + i, userId: userId, title: 'post ${from + i}', body: 'b'));

void main() {
  setUpAll(() {
    registerFallbackValue(const GetPostsParams(page: 1, limit: 10));
    registerFallbackValue(const NoParams());
    registerFallbackValue(const Post(id: 0, userId: 0, title: '', body: ''));
  });

  group('PostsCubit', () {
    late MockGetPosts getPosts;
    late PostsCubit cubit;

    PostsCubit build() {
      final getCached = MockGetCachedPosts();
      final getAuthors = MockGetAuthors();
      final getLocal = MockGetLocalPosts();
      when(() => getCached(any())).thenAnswer((_) async => const Right(null));
      when(() => getAuthors(any())).thenAnswer(
          (_) async => const Right([Author(id: 1, name: 'Leanne')]));
      when(() => getLocal(any())).thenAnswer((_) async => const Right([]));
      return PostsCubit(
        getPosts: getPosts,
        getCachedPosts: getCached,
        getAuthors: getAuthors,
        getLocalPosts: getLocal,
        saveLocalPost: MockSaveLocalPost(),
        filterPosts: const FilterPostsUseCase(),
      );
    }

    setUp(() => getPosts = MockGetPosts());
    tearDown(() => cubit.close());

    test('Loading → Success', () async {
      when(() => getPosts(const GetPostsParams(page: 1, limit: 10)))
          .thenAnswer((_) async => Right(makePosts(1, 10)));
      cubit = build();

      final statuses = <ListStatus>[];
      final sub = cubit.stream.listen((s) => statuses.add(s.status));
      await cubit.init();
      await Future<void>.delayed(Duration.zero); // доставка событий stream
      await sub.cancel();

      expect(statuses, contains(ListStatus.loading));
      expect(cubit.state.status, ListStatus.success);
      expect(cubit.state.visiblePosts, hasLength(10));
      expect(cubit.state.authorName(1), 'Leanne');
    });

    test('пустой ответ → Empty', () async {
      when(() => getPosts(any())).thenAnswer((_) async => const Right([]));
      cubit = build();

      await cubit.init();

      expect(cubit.state.status, ListStatus.empty);
    });

    test('ошибка → Error с понятным текстом, «Повторить» загружает снова',
        () async {
      when(() => getPosts(any()))
          .thenAnswer((_) async => const Left(ServerFailure()));
      cubit = build();

      await cubit.init();
      expect(cubit.state.status, ListStatus.failure);
      expect(cubit.state.failure?.message, const ServerFailure().message);

      when(() => getPosts(any()))
          .thenAnswer((_) async => Right(makePosts(1, 10)));
      await cubit.loadFirstPage();
      expect(cubit.state.status, ListStatus.success);
      expect(cubit.state.failure, isNull);
    });

    test('одна и та же страница не запрашивается дважды', () async {
      when(() => getPosts(const GetPostsParams(page: 1, limit: 10)))
          .thenAnswer((_) async => Right(makePosts(1, 10)));
      cubit = build();
      await cubit.init();

      final page2 = Completer<Either<Failure, List<Post>>>();
      when(() => getPosts(const GetPostsParams(page: 2, limit: 10)))
          .thenAnswer((_) => page2.future);

      final first = cubit.loadNextPage();
      unawaited(cubit.loadNextPage());
      unawaited(cubit.loadNextPage());
      page2.complete(Right(makePosts(11, 10)));
      await first;

      verify(() => getPosts(const GetPostsParams(page: 2, limit: 10)))
          .called(1);
      expect(cubit.state.posts, hasLength(20));
    });

    test('ответ для старого автора не смешивается с новым', () async {
      final slowAll = Completer<Either<Failure, List<Post>>>();
      when(() => getPosts(const GetPostsParams(page: 1, limit: 10)))
          .thenAnswer((_) => slowAll.future);
      when(() => getPosts(const GetPostsParams(page: 1, limit: 10, userId: 2)))
          .thenAnswer((_) async => Right(makePosts(11, 3, userId: 2)));
      cubit = build();

      unawaited(cubit.init());
      await Future<void>.delayed(Duration.zero);
      await cubit.selectAuthor(2);
      slowAll.complete(Right(makePosts(1, 10)));
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.posts.every((p) => p.userId == 2), isTrue);
      expect(cubit.state.posts, hasLength(3));
    });

    test('поиск фильтрует локально, без запросов', () async {
      when(() => getPosts(any()))
          .thenAnswer((_) async => Right(makePosts(1, 12)));
      cubit = build();
      await cubit.init();
      clearInteractions(getPosts);

      cubit.search('post 1');

      expect(cubit.state.visiblePosts.map((p) => p.id), [1, 10, 11, 12]);
      verifyZeroInteractions(getPosts);
    });
  });

  group('FavoritesCubit', () {
    const post = Post(id: 7, userId: 1, title: 't', body: 'b');
    late MockGetFavorites getFavorites;
    late MockToggleFavorite toggleFavorite;
    late FavoritesCubit cubit;

    setUp(() {
      getFavorites = MockGetFavorites();
      toggleFavorite = MockToggleFavorite();
      cubit = FavoritesCubit(
          getFavorites: getFavorites, toggleFavorite: toggleFavorite);
    });
    tearDown(() => cubit.close());

    test('пусто → Empty, после добавления → Success', () async {
      when(() => getFavorites(any())).thenAnswer((_) async => const Right([]));
      when(() => toggleFavorite(post))
          .thenAnswer((_) async => const Right([post]));

      await cubit.load();
      expect(cubit.state.status, FavoritesStatus.empty);

      final failure = await cubit.toggle(post);
      expect(failure, isNull);
      expect(cubit.state.status, FavoritesStatus.success);
      expect(cubit.state.isFavorite(7), isTrue);
    });

    test('двойное нажатие не запускает вторую запись', () async {
      final completer = Completer<Either<Failure, List<Post>>>();
      when(() => toggleFavorite(post)).thenAnswer((_) => completer.future);

      final first = cubit.toggle(post);
      await cubit.toggle(post);
      completer.complete(const Right([post]));
      await first;

      verify(() => toggleFavorite(post)).called(1);
    });

    test('ошибка сохранения возвращается как Failure, список не меняется',
        () async {
      when(() => getFavorites(any())).thenAnswer((_) async => const Right([]));
      when(() => toggleFavorite(post)).thenAnswer((_) async =>
          const Left(UnknownFailure('Не удалось сохранить данные на устройстве')));
      await cubit.load();

      final failure = await cubit.toggle(post);

      expect(failure, isA<UnknownFailure>());
      expect(cubit.state.favorites, isEmpty);
    });
  });
}
