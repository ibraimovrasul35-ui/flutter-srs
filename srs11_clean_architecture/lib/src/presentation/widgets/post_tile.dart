import 'package:flutter/material.dart';

import '../../../components/local_badge.dart';
import '../../domain/entities/post.dart';
import 'favorite_button.dart';

/// Карточка поста. Получает сущность Post (не DTO).
class PostTile extends StatelessWidget {
  final Post post;
  final String authorName;
  final VoidCallback onTap;

  const PostTile({
    super.key,
    required this.post,
    required this.authorName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: post.isLocal ? scheme.tertiaryContainer : null,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.only(left: 16, right: 4),
        leading: CircleAvatar(
          child: post.isLocal
              ? const Icon(Icons.phone_android, size: 20)
              : Text('${post.id}'),
        ),
        trailing: FavoriteButton(post: post),
        title: Text(post.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(post.body, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(authorName,
                    style: TextStyle(color: scheme.primary, fontSize: 12)),
                if (post.isLocal) const LocalBadge(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
