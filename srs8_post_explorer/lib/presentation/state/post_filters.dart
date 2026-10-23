import '../../data/models/post.dart';

/// Локальная фильтрация и сортировка уже загруженных постов.
/// Поиск по заголовку идёт только среди загруженных данных —
/// это явно подписано в интерфейсе.
List<Post> applyPostFilters(
  List<Post> posts, {
  String query = '',
  int? userId,
  bool ascending = true,
}) {
  final q = query.trim().toLowerCase();
  final result = posts.where((p) {
    if (userId != null && p.userId != userId) return false;
    if (q.isNotEmpty && !p.title.toLowerCase().contains(q)) return false;
    return true;
  }).toList();
  result.sort((a, b) => ascending ? a.id.compareTo(b.id) : b.id.compareTo(a.id));
  return result;
}
