import '../../../models/comment_model.dart';
import '../../../models/favorite_model.dart';
import '../../../models/post_model.dart';
import '../../../models/user_model.dart';
import '../../domain/entities/author.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/post.dart';

/// Model (DTO) → Entity и обратно. Только здесь Data Layer «переводит»
/// формат сервера в сущности, с которыми работает приложение.

extension PostModelMapper on PostModel {
  Post toEntity({bool isLocal = false}) => Post(
        id: id,
        userId: userId,
        title: title,
        body: body,
        isLocal: isLocal,
      );
}

extension PostEntityMapper on Post {
  PostModel toModel() =>
      PostModel(id: id, userId: userId, title: title, body: body);
}

extension CommentModelMapper on CommentModel {
  Comment toEntity() =>
      Comment(id: id, postId: postId, name: name, email: email, body: body);
}

extension UserModelMapper on UserModel {
  Author toEntity() => Author(
        id: id,
        name: name,
        email: email,
        companyName: company?.name,
        city: address?.city,
      );
}

extension FavoriteModelMapper on FavoriteModel {
  Post toEntity() => post.toEntity(isLocal: isLocal);
}
