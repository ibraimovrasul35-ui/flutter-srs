import '../../../constants/storage_keys.dart';
import '../../../models/comment_model.dart';
import '../../../models/post_model.dart';
import '../../domain/entities/cached.dart';
import 'json_storage.dart';

/// Кэш постов, деталей и комментариев + посты, созданные на устройстве.
abstract interface class PostLocalDataSource {
  Cached<List<PostModel>>? readPosts(int? userId);

  Future<void> savePosts(int? userId, List<PostModel> posts);

  Cached<PostModel>? readPost(int id);

  Future<void> savePost(PostModel post);

  Cached<List<CommentModel>>? readComments(int postId);

  Future<void> saveComments(int postId, List<CommentModel> comments);

  List<PostModel> readLocalPosts();

  Future<void> saveLocalPosts(List<PostModel> posts);
}

class PostLocalDataSourceImpl implements PostLocalDataSource {
  final JsonStorage _storage;

  const PostLocalDataSourceImpl(this._storage);

  @override
  Cached<List<PostModel>>? readPosts(int? userId) =>
      _storage.readList(StorageKeys.posts(userId), PostModel.fromJson);

  @override
  Future<void> savePosts(int? userId, List<PostModel> posts) =>
      _storage.writeList(
          StorageKeys.posts(userId), posts.map((p) => p.toJson()).toList());

  @override
  Cached<PostModel>? readPost(int id) {
    final cached = _storage.readList(StorageKeys.post(id), PostModel.fromJson);
    if (cached == null || cached.data.isEmpty) return null;
    return Cached(cached.data.first, cached.savedAt);
  }

  @override
  Future<void> savePost(PostModel post) =>
      _storage.writeList(StorageKeys.post(post.id), [post.toJson()]);

  @override
  Cached<List<CommentModel>>? readComments(int postId) =>
      _storage.readList(StorageKeys.comments(postId), CommentModel.fromJson);

  @override
  Future<void> saveComments(int postId, List<CommentModel> comments) =>
      _storage.writeList(StorageKeys.comments(postId),
          comments.map((c) => c.toJson()).toList());

  @override
  List<PostModel> readLocalPosts() =>
      _storage.readList(StorageKeys.localPosts, PostModel.fromJson)?.data ??
      const [];

  @override
  Future<void> saveLocalPosts(List<PostModel> posts) => _storage.writeList(
      StorageKeys.localPosts, posts.map((p) => p.toJson()).toList());
}
