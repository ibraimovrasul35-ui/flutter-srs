import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:srs8_post_explorer/core/error/app_exception.dart';
import 'package:srs8_post_explorer/data/models/comment.dart';
import 'package:srs8_post_explorer/data/models/post.dart';
import 'package:srs8_post_explorer/data/models/user.dart';

void main() {
  group('Post JSON', () {
    // Тест 1
    test('успешно преобразует JSON в Post', () {
      final post = Post.fromJson({
        'userId': 1,
        'id': 7,
        'title': 'magnam facilis autem',
        'body': 'dolore placeat quibusdam',
      });

      expect(post.id, 7);
      expect(post.userId, 1);
      expect(post.title, 'magnam facilis autem');
      expect(post.body, 'dolore placeat quibusdam');
      expect(post.isLocal, isFalse);
    });

    // Тест 2
    test('преобразует Post обратно в JSON', () {
      const post = Post(id: 3, userId: 2, title: 'Заголовок', body: 'Текст');

      expect(post.toJson(), {
        'id': 3,
        'userId': 2,
        'title': 'Заголовок',
        'body': 'Текст',
      });
      // Флаг isLocal — только для UI, в JSON не попадает.
      expect(post.toJson().containsKey('isLocal'), isFalse);
    });

    test('необязательное поле body по умолчанию пустое', () {
      final post = Post.fromJson({'id': 1, 'userId': 1, 'title': 'abc'});
      expect(post.body, '');
    });

    test('нет обязательного поля -> понятная ошибка parsing, а не падение', () {
      Object? error;
      try {
        Post.fromJson({'userId': 1, 'body': 'без id и title'});
      } catch (e) {
        error = e;
      }
      // В режиме checked отсутствие ключа оборачивается в CheckedFromJsonException.
      expect(error, isA<CheckedFromJsonException>());
      expect((error as CheckedFromJsonException).innerError,
          isA<MissingRequiredKeysException>());
      expect(ErrorMapper.map(error).type, AppErrorType.parsing);
    });

    test('неверный тип поля -> ошибка parsing', () {
      Object? error;
      try {
        Post.fromJson({'id': 'не число', 'userId': 1, 'title': 'abc'});
      } catch (e) {
        error = e;
      }
      expect(error, isA<CheckedFromJsonException>());
      expect(ErrorMapper.map(error!).type, AppErrorType.parsing);
    });
  });

  group('Вложенные модели и nullable-поля', () {
    test('User разбирает вложенные Address, Geo и Company', () {
      final user = User.fromJson({
        'id': 1,
        'name': 'Leanne Graham',
        'username': 'Bret',
        'email': 'Sincere@april.biz',
        'address': {
          'street': 'Kulas Light',
          'city': 'Gwenborough',
          'geo': {'lat': '-37.3159', 'lng': '81.1496'},
        },
        'company': {'name': 'Romaguera-Crona'},
      });

      expect(user.address?.city, 'Gwenborough');
      expect(user.address?.geo?.lat, '-37.3159');
      expect(user.company?.name, 'Romaguera-Crona');
      expect(user.phone, isNull);
      expect(user.toJson()['address']['geo'], {'lat': '-37.3159', 'lng': '81.1496'});
    });

    test('Comment без email', () {
      final c = Comment.fromJson(
          {'id': 1, 'postId': 1, 'name': 'id labore', 'body': 'laudantium'});
      expect(c.email, isNull);
    });
  });
}
