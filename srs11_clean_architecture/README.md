# СРС 11 — Post Explorer на Clean Architecture

Переписанная по Clean Architecture версия СРС 8 (`../srs8_post_explorer`):
просмотр, поиск и создание постов из [JSONPlaceholder](https://jsonplaceholder.typicode.com).
Новая функция: **избранное с локальным сохранением**.

Выполнил: Ибраимов Расул, группа Digital marketing 23.314.

## Запуск

```
cd srs11_clean_architecture
flutter pub get
dart run build_runner build   # генерация *.g.dart (уже лежат в репозитории)
flutter run
flutter test                  # 37 тестов
```

## Структура

```
lib/
├── components/        общие виджеты: Loading/Error/Empty, CacheBanner, LocalBadge
├── constants/         ApiConstants (baseUrl, таймауты, размер страницы), StorageKeys
├── models/            DTO: PostModel, CommentModel, UserModel, FavoriteModel (json_serializable)
├── core/
│   ├── rest_client/   DioClient, ApiInterceptor, RestClient (Retrofit)
│   └── di/            injection.dart: GetIt, все зависимости в одном месте
├── src/
│   ├── data/
│   │   ├── datasources/   Remote (посты, авторы) и Local (кэш, авторы, избранное)
│   │   ├── exceptions/    иерархия AppException + ExceptionMapper (Dio → AppException)
│   │   ├── mapper/        Model → Entity, AppException → Failure, guard()
│   │   └── repositories/  PostRepositoryImpl, AuthorRepositoryImpl, FavoritesRepositoryImpl
│   ├── domain/            только чистый Dart
│   │   ├── entities/      Post, Comment, Author, PostDetails, Cached, PostFilter
│   │   ├── failures/      иерархия Failure
│   │   ├── repositories/  абстрактные PostRepository, AuthorRepository, FavoritesRepository
│   │   ├── usecases/      GetPostsUseCase, CreatePostUseCase, ToggleFavoriteUseCase …
│   │   └── validators/    PostValidator (правила для нового поста)
│   └── presentation/
│       ├── pages/         PostsPage, PostDetailsPage, CreatePostPage, FavoritesPage
│       ├── widgets/       PostTile, FavoriteButton, FiltersBar, ListFooter, CommentTile
│       └── bloc/          PostsCubit, PostDetailsCubit, CreatePostCubit, FavoritesCubit
└── main.dart          initDependencies() → runApp
```

Зависимости направлены внутрь: `presentation → domain ← data`.
Domain не знает ни о Flutter, ни о Dio, ни о SharedPreferences. Это проверяет тест
`test/domain/domain_purity_test.dart`: он читает все import'ы в `lib/src/domain`.

## 1. Domain Layer

| Функция | Entity | Repository | UseCase |
|---|---|---|---|
| Список постов (пагинация, фильтр по автору) | `Post` | `PostRepository` | `GetPostsUseCase`, `GetCachedPostsUseCase` |
| Детали поста | `PostDetails`, `Comment` | `PostRepository` | `GetPostDetailsUseCase`, `GetCachedPostDetailsUseCase` |
| Создание поста | `Post` | `PostRepository` | `CreatePostUseCase`, `SaveLocalPostUseCase`, `GetLocalPostsUseCase` |
| Авторы | `Author` | `AuthorRepository` | `GetAuthorsUseCase`, `GetAuthorUseCase` |
| Поиск и сортировка | `PostFilter` | — | `FilterPostsUseCase` (синхронный, ошибок не бывает) |
| **Избранное (новое)** | `Post` | `FavoritesRepository` | `GetFavoritesUseCase`, `ToggleFavoriteUseCase` |

Каждый UseCase возвращает `Future<Either<Failure, T>>` (пакет `fpdart`).
`CreatePostUseCase` сам проверяет данные через `PostValidator`. Если данные
неверны, запрос не отправляется, а возвращается `ValidationFailure`.

## 2. Data Layer

- **Remote DataSource**: `PostRemoteDataSource`, `AuthorRemoteDataSource` поверх Retrofit.
  Возвращают DTO, при ошибке бросают `AppException` (Dio дальше не выходит).
- **Local DataSource**: `PostLocalDataSource` (кэш списка, деталей, локальные посты),
  `AuthorLocalDataSource`, `FavoritesLocalDataSource`. Всё хранится в SharedPreferences
  через общий `JsonStorage`.
- **RepositoryImpl** реализует абстрактные репозитории, объединяет сеть и кэш
  и возвращает только сущности.
- **Mapper** (`mapper/post_mapper.dart`): `PostModel.toEntity()`, `UserModel.toEntity()`
  (вложенные Address/Company сворачиваются в `city`/`companyName`) и т. д.
  В UI DTO не попадают. Например, экран созданного поста раньше показывал JSON
  `post.toJson()`, теперь он показывает поля сущности.

## 3. Presentation Layer

- В виджетах нет запросов и бизнес-логики. Экраны отображают состояние Cubit'а и
  передают ему действия пользователя. Фильтрация и проверки перенесены в Domain.
- Состояния: `loading / success / empty / failure` в `PostsState`, `FavoritesState`,
  `CreatePostState` (список авторов) и `PostDetailsState` (empty = нет комментариев).
- Ошибки показываются текстом из `Failure.message`. Везде есть кнопка «Повторить»
  и pull-to-refresh (также на экранах ошибки и пустого списка).
- Без лишних запросов:
  - следующая страница не запрашивается повторно, пока грузится текущая;
  - ответы для старого фильтра автора отбрасываются (счётчик «поколений»);
  - повторный pull-to-refresh во время загрузки игнорируется;
  - поиск идёт локально и не делает запросов;
  - авторы загружаются один раз за запуск: одновременные вызовы ждут один и тот же
    запрос, а экран деталей и форма берут автора из памяти;
  - двойное нажатие на ☆ и на «Отправить» не запускает вторую операцию.

## 4. Dependency Injection (GetIt)

`lib/core/di/injection.dart` регистрирует зависимости по порядку:
внешние (SharedPreferences, Dio, RestClient) → **DataSource → Repository → UseCase → Cubit**.
Cubit'ы регистрируются как `factory`. `PostDetailsCubit` регистрируется через
`registerFactoryParam` и получает пост как параметр. Экраны получают готовый Cubit
(`sl<PostDetailsCubit>(param1: post)`) и сами не создают ни репозитории, ни DataSource.

## 5. Обработка ошибок

Data Layer бросает исключения (`src/data/exceptions/exceptions.dart`):

```
AppException
├── NetworkException            нет соединения
├── RequestTimeoutException     таймаут
├── HttpStatusException
│   ├── ServerException         5xx
│   ├── UnauthorizedException   401
│   ├── BadRequestException     400, 422
│   └── UnexpectedStatusException  прочие коды (403, 404 …)
├── ParsingException            JSON не того формата
├── CacheException              ошибка хранилища
└── UnknownException
```

Репозиторий через `guard()` превращает их в `Failure` (`src/domain/failures/failures.dart`):

| Ситуация | Что возвращается |
|---|---|
| Нет интернета / таймаут | `NetworkFailure` |
| 500 (любой 5xx) | `ServerFailure` |
| 401 | `UnauthorizedFailure` |
| 400 (и 422), неверные данные формы | `ValidationFailure` |
| Пустой результат | `Right([])` → состояние **Empty** |
| Всё остальное (404, битый JSON, хранилище …) | `UnknownFailure` |

У каждого Failure заранее заданный понятный текст. Технические подробности
(`details`, стек) пишутся только в лог через `dart:developer`.
Тесты проверяют, что текст `SocketException` и ответ сервера на экран не попадают.

## 6. Новая функция: избранное с локальным сохранением

- Звёздочка ☆ на карточке поста и на экране деталей; экран «Избранное» с
  количеством на значке в AppBar.
- Хранится в SharedPreferences (`FavoriteModel`: пост целиком + время добавления),
  поэтому работает без интернета и сохраняется после перезапуска. Локально
  созданные посты тоже можно добавить в избранное.
- Слои: `FavoritesLocalDataSource` → `FavoritesRepositoryImpl` →
  `GetFavoritesUseCase` / `ToggleFavoriteUseCase` → `FavoritesCubit` (один на всё
  приложение, поэтому звёздочки везде совпадают).
- Состояния Loading / Success / Empty («В избранном пока пусто») / Error с «Повторить».
  Если сохранить не удалось, показывается SnackBar с текстом `UnknownFailure`.

## Тесты (`flutter test`, 37 шт.)

| Файл | Что проверяет |
|---|---|
| `test/domain/domain_purity_test.dart` | в Domain нет Flutter/Dio/http/Firebase/Data |
| `test/domain/usecases_test.dart` | валидация в `CreatePostUseCase`, `GetPostsUseCase`, поиск/сортировка |
| `test/data/post_repository_impl_test.dart` | 500/503/401/400/404, нет сети, таймаут, битый JSON, Empty, кэш, пагинация, POST |
| `test/data/author_and_favorites_repository_test.dart` | маппинг User→Author, один запрос авторов, offline, избранное между запусками |
| `test/presentation/cubits_test.dart` | Loading→Success, Empty, Error→«Повторить», нет дублей страниц, фильтры не смешиваются, избранное |
| `test/widget/app_test.dart` | всё приложение с настоящим DI: ошибка → «Повторить» → список; добавление в избранное |
