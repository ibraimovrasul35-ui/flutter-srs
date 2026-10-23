import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_exception.dart';
import '../../data/models/comment.dart';
import '../../data/models/post.dart';
import '../../data/models/user.dart';
import '../../data/repositories/post_repository.dart';

enum DetailsStatus { loading, success, failure }

final class PostDetailsState extends Equatable {
  final DetailsStatus status;
  final Post post;
  final List<Comment> comments;
  final User? author;
  final bool isFromCache;
  final String? errorMessage;

  const PostDetailsState({
    required this.post,
    this.status = DetailsStatus.loading,
    this.comments = const [],
    this.author,
    this.isFromCache = false,
    this.errorMessage,
  });

  PostDetailsState copyWith({
    DetailsStatus? status,
    Post? post,
    List<Comment>? comments,
    User? author,
    bool? isFromCache,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PostDetailsState(
      status: status ?? this.status,
      post: post ?? this.post,
      comments: comments ?? this.comments,
      author: author ?? this.author,
      isFromCache: isFromCache ?? this.isFromCache,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, post, comments, author, isFromCache, errorMessage];
}

class PostDetailsCubit extends Cubit<PostDetailsState> {
  final PostRepository _repository;

  /// [post] — пост из списка: его заголовок и текст видны сразу,
  /// пока догружаются актуальные данные и комментарии.
  PostDetailsCubit(this._repository, Post post)
      : super(PostDetailsState(post: post));

  Future<void> load() async {
    final post = state.post;

    // Локальный пост на сервере не существует — запрашивать нечего.
    if (post.isLocal) {
      emit(state.copyWith(status: DetailsStatus.success));
      return;
    }

    final cachedPost = _repository.getCachedPost(post.id);
    final cachedComments = _repository.getCachedComments(post.id);
    if (cachedComments != null) {
      emit(state.copyWith(
        status: DetailsStatus.success,
        post: cachedPost?.data,
        comments: cachedComments.data,
        isFromCache: true,
      ));
    } else {
      emit(state.copyWith(status: DetailsStatus.loading, clearError: true));
    }

    _loadAuthor(post.userId);

    try {
      final results = await Future.wait([
        _repository.fetchPost(post.id),
        _repository.fetchComments(post.id),
      ]);
      if (isClosed) return;
      emit(state.copyWith(
        status: DetailsStatus.success,
        post: results[0] as Post,
        comments: results[1] as List<Comment>,
        isFromCache: false,
        clearError: true,
      ));
    } on AppException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        status: state.isFromCache ? DetailsStatus.success : DetailsStatus.failure,
        errorMessage: e.message,
      ));
    }
  }

  Future<void> _loadAuthor(int userId) async {
    try {
      final author = await _repository.fetchUser(userId);
      if (!isClosed) emit(state.copyWith(author: author));
    } on AppException {
      // Автор — дополнительная информация, без него экран работает.
    }
  }
}
