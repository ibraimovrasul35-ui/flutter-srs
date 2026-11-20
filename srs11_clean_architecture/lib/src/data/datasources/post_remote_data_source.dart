import '../../../core/rest_client/rest_client.dart';
import '../../../models/comment_model.dart';
import '../../../models/post_model.dart';
import '../exceptions/exception_mapper.dart';

/// Посты и комментарии с сервера. Возвращает DTO, а при ошибке
/// бросает исключение из иерархии AppException (не DioException).
abstract interface class PostRemoteDataSource {
  Future<List<PostModel>> getPosts({
    required int page,
    required int limit,
    int? userId,
  });

  Future<PostModel> getPost(int id);

  Future<List<CommentModel>> getComments(int postId);

  Future<PostModel> createPost(CreatePostRequestModel request);
}

class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  final RestClient _client;

  const PostRemoteDataSourceImpl(this._client);

  @override
  Future<List<PostModel>> getPosts({
    required int page,
    required int limit,
    int? userId,
  }) =>
      _call(() => userId == null
          ? _client.getPosts(page, limit)
          : _client.getPostsByUser(userId, page, limit));

  @override
  Future<PostModel> getPost(int id) => _call(() => _client.getPost(id));

  @override
  Future<List<CommentModel>> getComments(int postId) =>
      _call(() => _client.getComments(postId));

  @override
  Future<PostModel> createPost(CreatePostRequestModel request) =>
      _call(() => _client.createPost(request));

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } catch (e) {
      throw ExceptionMapper.map(e);
    }
  }
}
