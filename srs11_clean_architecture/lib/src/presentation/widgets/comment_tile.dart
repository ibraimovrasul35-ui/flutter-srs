import 'package:flutter/material.dart';

import '../../domain/entities/author.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/post.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;

  const CommentTile({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        title: Text(comment.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (comment.email != null)
              Text(comment.email!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12)),
            const SizedBox(height: 4),
            Text(comment.body),
          ],
        ),
      ),
    );
  }
}

class AuthorCard extends StatelessWidget {
  final Post post;
  final Author? author;

  const AuthorCard({super.key, required this.post, this.author});

  @override
  Widget build(BuildContext context) {
    final a = author;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.person),
        title: Text(a?.name ?? 'Автор: userId ${post.userId}'),
        subtitle: a == null
            ? null
            : Text([
                if (a.email != null) a.email!,
                if (a.companyName != null) 'Компания: ${a.companyName}',
                if (a.city != null) 'Город: ${a.city}',
              ].join('\n')),
      ),
    );
  }
}
