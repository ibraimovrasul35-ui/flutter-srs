import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/comment.dart';
import '../models/post.dart';
import '../models/user.dart';

part 'post_api.g.dart';

/// Описание REST API JSONPlaceholder. Реализацию генерирует retrofit_generator.
@RestApi()
abstract class PostApi {
  factory PostApi(Dio dio, {String? baseUrl, ParseErrorLogger? errorLogger}) =
      _PostApi;

  /// 1. Список постов с пагинацией: GET /posts?_page=1&_limit=10
  @GET('/posts')
  Future<List<Post>> getPosts(
    @Query('_page') int page,
    @Query('_limit') int limit, {
    @CancelRequest() CancelToken? cancelToken,
  });

  /// 2. Подробная информация о посте: GET /posts/{id}
  @GET('/posts/{id}')
  Future<Post> getPost(@Path('id') int id);

  /// 3. Посты конкретного пользователя: GET /posts?userId={id}
  /// (с пагинацией — для фильтра по автору).
  @GET('/posts')
  Future<List<Post>> getPostsByUser(
    @Query('userId') int userId, {
    @Query('_page') int? page,
    @Query('_limit') int? limit,
    @CancelRequest() CancelToken? cancelToken,
  });

  /// 4. Комментарии к посту: GET /posts/{id}/comments
  @GET('/posts/{id}/comments')
  Future<List<Comment>> getComments(@Path('id') int postId);

  /// 5. Создание поста: POST /posts
  @POST('/posts')
  Future<Post> createPost(@Body() CreatePostRequest request);

  /// Доп.: список авторов: GET /users
  @GET('/users')
  Future<List<User>> getUsers();

  /// Доп.: информация об авторе: GET /users/{id}
  @GET('/users/{id}')
  Future<User> getUser(@Path('id') int id);
}
