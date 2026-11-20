part of 'post_details_cubit.dart';

enum DetailsStatus { loading, success, failure }

const _unset = Object();

final class PostDetailsState extends Equatable {
  final DetailsStatus status;
  final Post post;
  final List<Comment> comments;
  final Author? author;
  final bool isFromCache;
  final Failure? failure;

  const PostDetailsState({
    required this.post,
    this.status = DetailsStatus.loading,
    this.comments = const [],
    this.author,
    this.isFromCache = false,
    this.failure,
  });

  /// Empty: пост загружен, но комментариев нет.
  bool get hasNoComments =>
      status == DetailsStatus.success && comments.isEmpty;

  PostDetailsState copyWith({
    DetailsStatus? status,
    Post? post,
    List<Comment>? comments,
    Author? author,
    bool? isFromCache,
    Object? failure = _unset,
  }) {
    return PostDetailsState(
      status: status ?? this.status,
      post: post ?? this.post,
      comments: comments ?? this.comments,
      author: author ?? this.author,
      isFromCache: isFromCache ?? this.isFromCache,
      failure: identical(failure, _unset) ? this.failure : failure as Failure?,
    );
  }

  @override
  List<Object?> get props =>
      [status, post, comments, author, isFromCache, failure];
}
