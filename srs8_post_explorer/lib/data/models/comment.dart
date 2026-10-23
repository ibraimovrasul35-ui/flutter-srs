import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'comment.g.dart';

@JsonSerializable(checked: true)
class Comment extends Equatable {
  @JsonKey(required: true)
  final int id;

  @JsonKey(required: true)
  final int postId;

  @JsonKey(defaultValue: '')
  final String name;

  /// Необязательное поле: у комментария может не быть почты.
  final String? email;

  @JsonKey(defaultValue: '')
  final String body;

  const Comment({
    required this.id,
    required this.postId,
    required this.name,
    required this.body,
    this.email,
  });

  factory Comment.fromJson(Map<String, dynamic> json) =>
      _$CommentFromJson(json);

  Map<String, dynamic> toJson() => _$CommentToJson(this);

  @override
  List<Object?> get props => [id, postId, name, email, body];
}
