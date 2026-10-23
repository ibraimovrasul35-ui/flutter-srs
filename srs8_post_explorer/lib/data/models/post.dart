import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'post.g.dart';

/// Пост JSONPlaceholder.
///
/// `checked: true` + `required: true` — при отсутствии обязательного поля
/// или неверном типе бросается CheckedFromJsonException, которую
/// репозиторий превращает в понятную ошибку, а приложение не падает.
@JsonSerializable(checked: true)
class Post extends Equatable {
  @JsonKey(required: true)
  final int id;

  @JsonKey(required: true)
  final int userId;

  @JsonKey(required: true)
  final String title;

  @JsonKey(defaultValue: '')
  final String body;

  /// Пост создан через POST и хранится только на устройстве
  /// (JSONPlaceholder не сохраняет новые посты). В JSON не попадает.
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool isLocal;

  const Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.isLocal = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  Map<String, dynamic> toJson() => _$PostToJson(this);

  Post copyWith({int? id, int? userId, String? title, String? body, bool? isLocal}) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      isLocal: isLocal ?? this.isLocal,
    );
  }

  @override
  List<Object?> get props => [id, userId, title, body, isLocal];
}

/// Тело запроса POST /posts.
@JsonSerializable()
class CreatePostRequest {
  final String title;
  final String body;
  final int userId;

  const CreatePostRequest({
    required this.title,
    required this.body,
    required this.userId,
  });

  factory CreatePostRequest.fromJson(Map<String, dynamic> json) =>
      _$CreatePostRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreatePostRequestToJson(this);
}
