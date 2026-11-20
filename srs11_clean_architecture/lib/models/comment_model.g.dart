// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommentModel _$CommentModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CommentModel', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'postId']);
      final val = CommentModel(
        id: $checkedConvert('id', (v) => (v as num).toInt()),
        postId: $checkedConvert('postId', (v) => (v as num).toInt()),
        name: $checkedConvert('name', (v) => v as String? ?? ''),
        body: $checkedConvert('body', (v) => v as String? ?? ''),
        email: $checkedConvert('email', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$CommentModelToJson(CommentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'postId': instance.postId,
      'name': instance.name,
      'email': instance.email,
      'body': instance.body,
    };
