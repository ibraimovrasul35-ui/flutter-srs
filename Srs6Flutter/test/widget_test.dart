import 'package:flutter_test/flutter_test.dart';

import 'package:srs6_flutter/models/get_posts.dart';

void main() {
  test('Posts.fromJson parses a post', () {
    final post = Posts.fromJson({
      'userId': 1,
      'id': 1,
      'title': 'Hello',
      'body': 'World',
    });

    expect(post.id, 1);
    expect(post.title, 'Hello');
    expect(post.body, 'World');
    expect(post.toJson(), {'id': 1, 'title': 'Hello', 'body': 'World'});
  });
}
