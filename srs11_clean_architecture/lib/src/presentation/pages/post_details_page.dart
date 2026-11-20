import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../components/cache_banner.dart';
import '../../../components/local_badge.dart';
import '../../../components/state_views.dart';
import '../../../core/di/injection.dart';
import '../../domain/entities/post.dart';
import '../bloc/post_details/post_details_cubit.dart';
import '../widgets/comment_tile.dart';
import '../widgets/favorite_button.dart';

class PostDetailsPage extends StatelessWidget {
  const PostDetailsPage({super.key});

  /// Cubit берётся из DI: экран ничего не создаёт сам.
  static Route<void> route(Post post) => MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => sl<PostDetailsCubit>(param1: post)..load(),
          child: const PostDetailsPage(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostDetailsCubit, PostDetailsState>(
      builder: (context, state) {
        final cubit = context.read<PostDetailsCubit>();
        return Scaffold(
          appBar: AppBar(
            title: Text(
                state.post.isLocal ? 'Локальный пост' : 'Пост #${state.post.id}'),
            actions: [FavoriteButton(post: state.post)],
          ),
          body: RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (state.isFromCache)
                  CacheBanner(
                    error: state.failure?.message,
                    isUpdating: state.failure == null,
                  ),
                _PostHeader(state: state),
                const Divider(height: 32),
                ..._buildComments(context, state, cubit),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildComments(
    BuildContext context,
    PostDetailsState state,
    PostDetailsCubit cubit,
  ) {
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
          Padding(padding: EdgeInsets.all(24), child: LoadingView()),
        ];
      case DetailsStatus.failure:
        return [
          SizedBox(
            height: 240,
            child: ErrorView(
              message: state.failure?.message ??
                  'Не удалось загрузить комментарии',
              onRetry: cubit.load,
            ),
          ),
        ];
      case DetailsStatus.success:
        if (state.hasNoComments) {
          return const [
            SizedBox(
              height: 160,
              child: EmptyView(
                message: 'Комментариев нет',
                icon: Icons.chat_bubble_outline,
              ),
            ),
          ];
        }
        return [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Комментарии (${state.comments.length})',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          for (final c in state.comments) CommentTile(comment: c),
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
          AuthorCard(post: post, author: state.author),
        ],
      ),
    );
  }
}
