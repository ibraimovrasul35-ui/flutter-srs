import 'package:json_annotation/json_annotation.dart';

import 'post_model.dart';

part 'favorite_model.g.dart';

/// Запись избранного в локальном хранилище. Пост хранится целиком,
/// поэтому избранное открывается и без интернета.
@JsonSerializable(checked: true, explicitToJson: true)
class FavoriteModel {
  @JsonKey(required: true)
  final PostModel post;

  /// Пост создан на устройстве (на сервере его нет).
  @JsonKey(defaultValue: false)
  final bool isLocal;

  @JsonKey(required: true)
  final DateTime addedAt;

  const FavoriteModel({
    required this.post,
    required this.isLocal,
    required this.addedAt,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) =>
      _$FavoriteModelFromJson(json);

  Map<String, dynamic> toJson() => _$FavoriteModelToJson(this);
}
