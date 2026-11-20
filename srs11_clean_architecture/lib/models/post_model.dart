import 'package:json_annotation/json_annotation.dart';

part 'post_model.g.dart';

/// DTO поста JSONPlaceholder. Используется только в Data Layer:
/// в UI попадает сущность `Post` (см. `src/data/mapper/post_mapper.dart`).
///
/// `checked: true` + `required: true`: если обязательного поля нет или
/// у него неверный тип, бросается CheckedFromJsonException. Она
/// превращается в ParsingException и не роняет приложение.
@JsonSerializable(checked: true)
class PostModel {
  @JsonKey(required: true)
  final int id;

  @JsonKey(required: true)
  final int userId;

  @JsonKey(required: true)
  final String title;

  @JsonKey(defaultValue: '')
  final String body;

  const PostModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) =>
      _$PostModelFromJson(json);

  Map<String, dynamic> toJson() => _$PostModelToJson(this);
}

/// Тело запроса POST /posts.
@JsonSerializable()
class CreatePostRequestModel {
  final String title;
  final String body;
  final int userId;

  const CreatePostRequestModel({
    required this.title,
    required this.body,
    required this.userId,
  });

  factory CreatePostRequestModel.fromJson(Map<String, dynamic> json) =>
      _$CreatePostRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$CreatePostRequestModelToJson(this);
}
