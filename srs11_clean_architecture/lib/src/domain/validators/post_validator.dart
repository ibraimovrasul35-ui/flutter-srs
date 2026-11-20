/// Правила для нового поста. Это бизнес-правила, поэтому они в Domain:
/// ими пользуются и форма (подсказки под полями), и CreatePostUseCase
/// (проверка перед отправкой). Возвращают текст ошибки или null.
class PostValidator {
  const PostValidator._();

  static const titleMin = 5;
  static const titleMax = 100;
  static const bodyMin = 10;
  static const bodyMax = 1000;

  static String? title(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Введите заголовок';
    if (v.length < titleMin) return 'Минимум $titleMin символов';
    if (v.length > titleMax) return 'Максимум $titleMax символов';
    return null;
  }

  static String? body(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Введите текст поста';
    if (v.length < bodyMin) return 'Минимум $bodyMin символов';
    if (v.length > bodyMax) return 'Максимум $bodyMax символов';
    return null;
  }

  static String? author(int? userId) =>
      userId == null ? 'Выберите автора' : null;
}
