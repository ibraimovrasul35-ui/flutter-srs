// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FavoriteModel _$FavoriteModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FavoriteModel', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['post', 'addedAt']);
      final val = FavoriteModel(
        post: $checkedConvert(
          'post',
          (v) => PostModel.fromJson(v as Map<String, dynamic>),
        ),
        isLocal: $checkedConvert('isLocal', (v) => v as bool? ?? false),
        addedAt: $checkedConvert('addedAt', (v) => DateTime.parse(v as String)),
      );
      return val;
    });

Map<String, dynamic> _$FavoriteModelToJson(FavoriteModel instance) =>
    <String, dynamic>{
      'post': instance.post.toJson(),
      'isLocal': instance.isLocal,
      'addedAt': instance.addedAt.toIso8601String(),
    };
