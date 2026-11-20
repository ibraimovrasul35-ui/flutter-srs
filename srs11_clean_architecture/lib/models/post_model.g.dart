// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostModel _$PostModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PostModel', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'userId', 'title']);
      final val = PostModel(
        id: $checkedConvert('id', (v) => (v as num).toInt()),
        userId: $checkedConvert('userId', (v) => (v as num).toInt()),
        title: $checkedConvert('title', (v) => v as String),
        body: $checkedConvert('body', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$PostModelToJson(PostModel instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'title': instance.title,
  'body': instance.body,
};

CreatePostRequestModel _$CreatePostRequestModelFromJson(
  Map<String, dynamic> json,
) => CreatePostRequestModel(
  title: json['title'] as String,
  body: json['body'] as String,
  userId: (json['userId'] as num).toInt(),
);

Map<String, dynamic> _$CreatePostRequestModelToJson(
  CreatePostRequestModel instance,
) => <String, dynamic>{
  'title': instance.title,
  'body': instance.body,
  'userId': instance.userId,
};
