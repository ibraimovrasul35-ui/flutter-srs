import 'package:json_annotation/json_annotation.dart';

part 'comment_model.g.dart';

/// DTO комментария (GET /posts/{id}/comments).
@JsonSerializable(checked: true)
class CommentModel {
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

  const CommentModel({
    required this.id,
    required this.postId,
    required this.name,
    required this.body,
    this.email,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) =>
      _$CommentModelFromJson(json);

  Map<String, dynamic> toJson() => _$CommentModelToJson(this);
}
