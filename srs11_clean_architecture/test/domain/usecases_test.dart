import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:srs11_clean_architecture/src/domain/entities/post.dart';
import 'package:srs11_clean_architecture/src/domain/entities/post_filter.dart';
import 'package:srs11_clean_architecture/src/domain/failures/failures.dart';
import 'package:srs11_clean_architecture/src/domain/repositories/post_repository.dart';
import 'package:srs11_clean_architecture/src/domain/usecases/create_post_usecase.dart';
import 'package:srs11_clean_architecture/src/domain/usecases/filter_posts_usecase.dart';
import 'package:srs11_clean_architecture/src/domain/usecases/get_posts_usecase.dart';

class MockPostRepository extends Mock implements PostRepository {}

void main() {
  late MockPostRepository repository;

  setUp(() => repository = MockPostRepository());

  group('CreatePostUseCase', () {
    test('неверные данные → ValidationFailure, запрос не отправляется',
        () async {
      final useCase = CreatePostUseCase(repository);

      final result = await useCase(
          const CreatePostParams(title: 'abc', body: 'короткий', userId: 1));

      expect(result, const Left(ValidationFailure('Минимум 5 символов')));
      verifyNever(() => repository.createPost(
          title: any(named: 'title'),
          body: any(named: 'body'),
          userId: any(named: 'userId')));
    });

    test('без автора → ValidationFailure', () async {
      final result = await CreatePostUseCase(repository)(const CreatePostParams(
          title: 'Заголовок', body: 'Достаточно длинный текст', userId: null));

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('верные данные обрезаются и уходят в репозиторий', () async {
      const created = Post(id: 101, userId: 2, title: 'Заголовок', body: 'Текст поста!');
      when(() => repository.createPost(
              title: 'Заголовок', body: 'Текст поста!', userId: 2))
          .thenAnswer((_) async => const Right(created));

      final result = await CreatePostUseCase(repository)(const CreatePostParams(
          title: '  Заголовок ', body: ' Текст поста! ', userId: 2));

      expect(result, const Right(created));
    });
  });

  test('GetPostsUseCase: страница < 1 → ValidationFailure без запроса',
      () async {
    final result =
        await GetPostsUseCase(repository)(const GetPostsParams(page: 0, limit: 10));

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyZeroInteractions(repository);
  });

  group('FilterPostsUseCase', () {
    const posts = [
      Post(id: 2, userId: 1, title: 'Flutter и Dart', body: ''),
      Post(id: 1, userId: 2, title: 'Clean Architecture', body: ''),
      Post(id: 3, userId: 1, title: 'Dart streams', body: ''),
    ];
    const filter = FilterPostsUseCase();

    test('поиск без учёта регистра + сортировка по id', () {
      final result = filter(posts, const PostFilter(query: 'DART'));
      expect(result.map((p) => p.id), [2, 3]);
    });

    test('фильтр по автору и сортировка по убыванию', () {
      final result =
          filter(posts, const PostFilter(userId: 1, ascending: false));
      expect(result.map((p) => p.id), [3, 2]);
    });
  });
}
