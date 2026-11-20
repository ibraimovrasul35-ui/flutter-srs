import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../models/comment_model.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';

part 'rest_client.g.dart';

/// REST API JSONPlaceholder. Реализацию генерирует retrofit_generator.
/// Возвращает только DTO: сущности получаются в Data Layer через mapper.
@RestApi()
abstract class RestClient {
  factory RestClient(Dio dio,
      {String? baseUrl, ParseErrorLogger? errorLogger}) = _RestClient;

  /// Список постов с пагинацией: GET /posts?_page=1&_limit=10
  @GET('/posts')
  Future<List<PostModel>> getPosts(
    @Query('_page') int page,
    @Query('_limit') int limit,
  );

  /// Посты автора: GET /posts?userId={id}&_page=&_limit=
  @GET('/posts')
  Future<List<PostModel>> getPostsByUser(
    @Query('userId') int userId,
    @Query('_page') int page,
    @Query('_limit') int limit,
  );

  /// Пост: GET /posts/{id}
  @GET('/posts/{id}')
  Future<PostModel> getPost(@Path('id') int id);

  /// Комментарии: GET /posts/{id}/comments
  @GET('/posts/{id}/comments')
  Future<List<CommentModel>> getComments(@Path('id') int postId);

  /// Создание поста: POST /posts
  @POST('/posts')
  Future<PostModel> createPost(@Body() CreatePostRequestModel request);

  /// Авторы: GET /users
  @GET('/users')
  Future<List<UserModel>> getUsers();

  /// Автор: GET /users/{id}
  @GET('/users/{id}')
  Future<UserModel> getUser(@Path('id') int id);
}
