/// Ключи SharedPreferences. Версия в префиксе позволяет сбросить
/// старый формат кэша, если он поменяется.
class StorageKeys {
  const StorageKeys._();

  static const _prefix = 'cache_v2_';

  static const localPosts = '${_prefix}local_posts';
  static const users = '${_prefix}users';
  static const favorites = 'favorites_v1';

  static String posts(int? userId) =>
      userId == null ? '${_prefix}posts_all' : '${_prefix}posts_user_$userId';
  static String post(int id) => '${_prefix}post_$id';
  static String comments(int postId) => '${_prefix}comments_$postId';
}
