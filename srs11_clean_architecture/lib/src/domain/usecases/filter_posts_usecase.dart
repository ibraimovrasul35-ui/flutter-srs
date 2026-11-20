import '../entities/post.dart';
import '../entities/post_filter.dart';

/// Локальный поиск по заголовку, фильтр по автору и сортировка по id.
/// Работает с уже загруженными постами и не может завершиться ошибкой,
/// поэтому это синхронный сценарий без Either.
class FilterPostsUseCase {
  const FilterPostsUseCase();

  List<Post> call(List<Post> posts, PostFilter filter) {
    final q = filter.query.trim().toLowerCase();
    final result = posts.where((p) {
      if (filter.userId != null && p.userId != filter.userId) return false;
      if (q.isNotEmpty && !p.title.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
    result.sort((a, b) =>
        filter.ascending ? a.id.compareTo(b.id) : b.id.compareTo(a.id));
    return result;
  }
}
