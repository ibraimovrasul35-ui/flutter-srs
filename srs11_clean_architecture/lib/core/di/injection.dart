import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../src/data/datasources/author_local_data_source.dart';
import '../../src/data/datasources/author_remote_data_source.dart';
import '../../src/data/datasources/favorites_local_data_source.dart';
import '../../src/data/datasources/json_storage.dart';
import '../../src/data/datasources/post_local_data_source.dart';
import '../../src/data/datasources/post_remote_data_source.dart';
import '../../src/data/repositories/author_repository_impl.dart';
import '../../src/data/repositories/favorites_repository_impl.dart';
import '../../src/data/repositories/post_repository_impl.dart';
import '../../src/domain/entities/post.dart';
import '../../src/domain/repositories/author_repository.dart';
import '../../src/domain/repositories/favorites_repository.dart';
import '../../src/domain/repositories/post_repository.dart';
import '../../src/domain/usecases/create_post_usecase.dart';
import '../../src/domain/usecases/favorites_usecases.dart';
import '../../src/domain/usecases/filter_posts_usecase.dart';
import '../../src/domain/usecases/get_author_usecase.dart';
import '../../src/domain/usecases/get_authors_usecase.dart';
import '../../src/domain/usecases/get_cached_post_details_usecase.dart';
import '../../src/domain/usecases/get_cached_posts_usecase.dart';
import '../../src/domain/usecases/get_post_details_usecase.dart';
import '../../src/domain/usecases/get_posts_usecase.dart';
import '../../src/domain/usecases/local_posts_usecases.dart';
import '../../src/presentation/bloc/create_post/create_post_cubit.dart';
import '../../src/presentation/bloc/favorites/favorites_cubit.dart';
import '../../src/presentation/bloc/post_details/post_details_cubit.dart';
import '../../src/presentation/bloc/posts/posts_cubit.dart';
import '../rest_client/dio_client.dart';
import '../rest_client/rest_client.dart';

/// Единственный Service Locator приложения.
final sl = GetIt.instance;

/// Все зависимости регистрируются здесь и в строгом порядке:
/// внешние библиотеки → DataSource → Repository → UseCase → Bloc/Cubit.
///
/// Экраны получают только готовые Cubit'ы, а Cubit'ы — только UseCase.
/// [prefs] и [dio] передают тесты, чтобы подменить хранилище и сеть.
Future<void> initDependencies({SharedPreferences? prefs, Dio? dio}) async {
  await sl.reset();

  // ---------- 1. Внешние зависимости ----------
  final preferences = prefs ?? await SharedPreferences.getInstance();
  sl
    ..registerLazySingleton<SharedPreferences>(() => preferences)
    ..registerLazySingleton<Dio>(() => dio ?? DioClient.create())
    ..registerLazySingleton<RestClient>(() => RestClient(sl()))
    ..registerLazySingleton<JsonStorage>(() => JsonStorage(sl()));

  // ---------- 2. DataSource ----------
  sl
    ..registerLazySingleton<PostRemoteDataSource>(
        () => PostRemoteDataSourceImpl(sl()))
    ..registerLazySingleton<AuthorRemoteDataSource>(
        () => AuthorRemoteDataSourceImpl(sl()))
    ..registerLazySingleton<PostLocalDataSource>(
        () => PostLocalDataSourceImpl(sl()))
    ..registerLazySingleton<AuthorLocalDataSource>(
        () => AuthorLocalDataSourceImpl(sl()))
    ..registerLazySingleton<FavoritesLocalDataSource>(
        () => FavoritesLocalDataSourceImpl(sl()));

  // ---------- 3. Repository ----------
  sl
    ..registerLazySingleton<PostRepository>(
        () => PostRepositoryImpl(remote: sl(), local: sl()))
    // Singleton: хранит авторов в памяти, чтобы не запрашивать их повторно.
    ..registerLazySingleton<AuthorRepository>(
        () => AuthorRepositoryImpl(remote: sl(), local: sl()))
    ..registerLazySingleton<FavoritesRepository>(
        () => FavoritesRepositoryImpl(sl()));

  // ---------- 4. UseCase ----------
  sl
    ..registerLazySingleton(() => GetPostsUseCase(sl()))
    ..registerLazySingleton(() => GetCachedPostsUseCase(sl()))
    ..registerLazySingleton(() => GetPostDetailsUseCase(sl()))
    ..registerLazySingleton(() => GetCachedPostDetailsUseCase(sl()))
    ..registerLazySingleton(() => CreatePostUseCase(sl()))
    ..registerLazySingleton(() => GetLocalPostsUseCase(sl()))
    ..registerLazySingleton(() => SaveLocalPostUseCase(sl()))
    ..registerLazySingleton(() => const FilterPostsUseCase())
    ..registerLazySingleton(() => GetAuthorsUseCase(sl()))
    ..registerLazySingleton(() => GetAuthorUseCase(sl()))
    ..registerLazySingleton(() => GetFavoritesUseCase(sl()))
    ..registerLazySingleton(() => ToggleFavoriteUseCase(sl()));

  // ---------- 5. Bloc / Cubit (новый экземпляр на каждый экран) ----------
  sl
    ..registerFactory(() => PostsCubit(
          getPosts: sl(),
          getCachedPosts: sl(),
          getAuthors: sl(),
          getLocalPosts: sl(),
          saveLocalPost: sl(),
          filterPosts: sl(),
        ))
    ..registerFactoryParam<PostDetailsCubit, Post, void>(
        (post, _) => PostDetailsCubit(
              post: post,
              getDetails: sl(),
              getCachedDetails: sl(),
              getAuthor: sl(),
            ))
    ..registerFactory(
        () => CreatePostCubit(getAuthors: sl(), createPost: sl()))
    ..registerFactory(
        () => FavoritesCubit(getFavorites: sl(), toggleFavorite: sl()));
}
