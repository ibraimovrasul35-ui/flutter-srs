import 'package:equatable/equatable.dart';

/// Пост — сущность предметной области. Не знает ни о JSON, ни о сервере.
class Post extends Equatable {
  final int id;
  final int userId;
  final String title;
  final String body;

  /// Пост создан на устройстве: JSONPlaceholder принимает POST,
  /// но ничего не сохраняет, поэтому такой пост есть только локально.
  final bool isLocal;

  const Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.isLocal = false,
  });

  Post copyWith({
    int? id,
    int? userId,
    String? title,
    String? body,
    bool? isLocal,
  }) {
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
