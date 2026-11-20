import 'package:equatable/equatable.dart';

import 'comment.dart';
import 'post.dart';

/// Пост вместе с комментариями: то, что показывает экран деталей.
class PostDetails extends Equatable {
  final Post post;
  final List<Comment> comments;

  const PostDetails({required this.post, required this.comments});

  @override
  List<Object?> get props => [post, comments];
}
