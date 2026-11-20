import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../components/state_views.dart';
import '../bloc/favorites/favorites_cubit.dart';
import '../bloc/posts/posts_cubit.dart';
import '../widgets/post_tile.dart';
import 'post_details_page.dart';

/// Экран «Избранное». Данные лежат на устройстве, поэтому он работает
/// и без интернета.
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const FavoritesPage());

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FavoritesCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('Избранное')),
      body: BlocBuilder<FavoritesCubit, FavoritesState>(
        builder: (context, state) {
          switch (state.status) {
            case FavoritesStatus.loading:
              return const LoadingView();
            case FavoritesStatus.failure:
              return ErrorView(
                message: state.failure?.message ??
                    'Не удалось открыть избранное',
                onRetry: cubit.load,
              );
            case FavoritesStatus.empty:
              return const EmptyView(
                icon: Icons.star_border,
                message: 'В избранном пока пусто.\n'
                    'Нажмите ☆ у поста, чтобы сохранить его здесь.',
              );
            case FavoritesStatus.success:
              final authorName = context.read<PostsCubit>().state.authorName;
              return RefreshIndicator(
                onRefresh: cubit.load,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: state.favorites.length,
                  itemBuilder: (context, index) {
                    final post = state.favorites[index];
                    return PostTile(
                      key: ValueKey(post.id),
                      post: post,
                      authorName: authorName(post.userId),
                      onTap: () =>
                          Navigator.push(context, PostDetailsPage.route(post)),
                    );
                  },
                ),
              );
          }
        },
      ),
    );
  }
}
