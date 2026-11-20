import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srs11_clean_architecture/models/user_model.dart';
import 'package:srs11_clean_architecture/src/data/datasources/author_local_data_source.dart';
import 'package:srs11_clean_architecture/src/data/datasources/author_remote_data_source.dart';
import 'package:srs11_clean_architecture/src/data/datasources/favorites_local_data_source.dart';
import 'package:srs11_clean_architecture/src/data/datasources/json_storage.dart';
import 'package:srs11_clean_architecture/src/data/exceptions/exceptions.dart';
import 'package:srs11_clean_architecture/src/data/repositories/author_repository_impl.dart';
import 'package:srs11_clean_architecture/src/data/repositories/favorites_repository_impl.dart';
import 'package:srs11_clean_architecture/src/domain/entities/author.dart';
import 'package:srs11_clean_architecture/src/domain/entities/post.dart';
import 'package:srs11_clean_architecture/src/domain/failures/failures.dart';

class MockAuthorRemote extends Mock implements AuthorRemoteDataSource {}

void main() {
  late JsonStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = JsonStorage(await SharedPreferences.getInstance());
  });

  group('AuthorRepositoryImpl', () {
    late MockAuthorRemote remote;
    late AuthorRepositoryImpl repository;

    const users = [
      UserModel(
        id: 1,
        name: 'Leanne Graham',
        email: 'l@april.biz',
        address: AddressModel(city: 'Gwenborough'),
        company: CompanyModel(name: 'Romaguera-Crona'),
      ),
    ];

    setUp(() {
      remote = MockAuthorRemote();
      repository = AuthorRepositoryImpl(
          remote: remote, local: AuthorLocalDataSourceImpl(storage));
    });

    test('UserModel → Author: вложенные объекты сворачиваются в поля', () async {
      when(() => remote.getUsers()).thenAnswer((_) async => users);

      final authors = (await repository.getAuthors()).getOrElse((_) => []);

      expect(authors.single, const Author(
        id: 1,
        name: 'Leanne Graham',
        email: 'l@april.biz',
        companyName: 'Romaguera-Crona',
        city: 'Gwenborough',
      ));
    });

    test('нет лишних запросов: одновременные и повторные вызовы → 1 запрос, '
        'автор берётся из памяти', () async {
      final completer = Completer<List<UserModel>>();
      when(() => remote.getUsers()).thenAnswer((_) => completer.future);

      final a = repository.getAuthors();
      final b = repository.getAuthors();
      completer.complete(users);
      await Future.wait([a, b]);
      await repository.getAuthors();
      final author = await repository.getAuthor(1);

      verify(() => remote.getUsers()).called(1);
      verifyNever(() => remote.getUser(any()));
      expect(author.isRight(), isTrue);
    });

    test('offline: без сети отдаётся сохранённый список', () async {
      when(() => remote.getUsers()).thenAnswer((_) async => users);
      await repository.getAuthors();

      // Новый запуск приложения: памяти нет, сети нет.
      final fresh = AuthorRepositoryImpl(
          remote: remote, local: AuthorLocalDataSourceImpl(storage));
      when(() => remote.getUsers()).thenThrow(const NetworkException());

      final result = await fresh.getAuthors();
      expect(result.getOrElse((_) => []), hasLength(1));
    });

    test('без сети и без кэша → NetworkFailure', () async {
      when(() => remote.getUsers()).thenThrow(const NetworkException());

      final result = await repository.getAuthors();
      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
    });
  });

  group('FavoritesRepositoryImpl (новая функция)', () {
    const post1 = Post(id: 1, userId: 1, title: 'Первый', body: 'b');
    const local = Post(id: -5, userId: 2, title: 'Мой', body: 'b', isLocal: true);

    test('добавление, удаление и сохранение между запусками', () async {
      final repository =
          FavoritesRepositoryImpl(FavoritesLocalDataSourceImpl(storage));

      expect((await repository.getFavorites()).getOrElse((_) => [post1]),
          isEmpty);

      await repository.toggleFavorite(post1);
      final afterAdd =
          (await repository.toggleFavorite(local)).getOrElse((_) => []);
      expect(afterAdd.map((p) => p.id), [-5, 1]); // новые сверху
      expect(afterAdd.first.isLocal, isTrue);

      // «Перезапуск»: новый репозиторий читает то же хранилище.
      final reopened =
          FavoritesRepositoryImpl(FavoritesLocalDataSourceImpl(storage));
      expect((await reopened.getFavorites()).getOrElse((_) => []),
          hasLength(2));

      final afterRemove =
          (await reopened.toggleFavorite(post1)).getOrElse((_) => []);
      expect(afterRemove, [local]);
    });
  });
}
