import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:srs6_flutter/models/get_posts.dart';

class PostRepository {
  final _baseUrl = 'https://jsonplaceholder.typicode.com/posts';

  Future<List<Posts>> getPosts() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode != 200) {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList.map((json) => Posts.fromJson(json)).toList();
  }
}
