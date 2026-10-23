import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';
import '../state/post_details_cubit.dart';
import '../widgets/post_tile.dart';
import '../widgets/state_views.dart';

class PostDetailsScreen extends StatelessWidget {
  final Post post;

  const PostDetailsScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PostDetailsCubit(context.read<PostRepository>(), post)..load(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(post.isLocal ? 'Локальный пост' : 'Пост #${post.id}'),
        ),
        body: BlocBuilder<PostDetailsCubit, PostDetailsState>(
          builder: (context, state) {
            final cubit = context.read<PostDetailsCubit>();
            return RefreshIndicator(
              onRefresh: cubit.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  if (state.isFromCache)
                    CacheBanner(
                      error: state.errorMessage,
                      isUpdating: state.errorMessage == null,
                    ),
                  _PostHeader(state: state),
                  const Divider(height: 32),
                  ..._buildComments(context, state, cubit),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildComments(
    BuildContext context,
    PostDetailsState state,
    PostDetailsCubit cubit,
  ) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;

    if (state.post.isLocal) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Этот пост создан локально. JSONPlaceholder не сохраняет новые '
            'посты, поэтому на сервере его нет и комментариев к нему нет.',
          ),
        ),
      ];
    }

    switch (state.status) {
      case DetailsStatus.loading:
        return const [
          Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      case DetailsStatus.failure:
        return [
          SizedBox(
            height: 240,
            child: ErrorView(
              message: state.errorMessage ?? 'Не удалось загрузить комментарии',
              onRetry: cubit.load,
            ),
          ),
        ];
      case DetailsStatus.success:
        if (state.comments.isEmpty) {
          return const [
            SizedBox(height: 160, child: EmptyView(message: 'Комментариев нет')),
          ];
        }
        return [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Комментарии (${state.comments.length})',
                style: titleStyle),
          ),
          const SizedBox(height: 8),
          for (final c in state.comments)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                title: Text(c.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (c.email != null)
                      Text(c.email!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(c.body),
                  ],
                ),
              ),
            ),
        ];
    }
  }
}

class _PostHeader extends StatelessWidget {
  final PostDetailsState state;

  const _PostHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final post = state.post;
    final textTheme = Theme.of(context).textTheme;
    final author = state.author;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.isLocal) ...[
            const LocalBadge(),
            const SizedBox(height: 8),
          ],
          Text(post.title, style: textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(post.body, style: textTheme.bodyLarge),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text(author?.name ?? 'Автор: userId ${post.userId}'),
              subtitle: author == null
                  ? null
                  : Text([
                      if (author.email != null) author.email!,
                      if (author.company?.name != null)
                        'Компания: ${author.company!.name}',
                      if (author.address?.city != null)
                        'Город: ${author.address!.city}',
                    ].join('\n')),
            ),
          ),
        ],
      ),
    );
  }
}
