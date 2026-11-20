import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../components/cache_banner.dart';
import '../../../components/state_views.dart';
import '../../domain/entities/post.dart';
import '../bloc/favorites/favorites_cubit.dart';
import '../bloc/posts/posts_cubit.dart';
import '../widgets/filters_bar.dart';
import '../widgets/list_footer.dart';
import '../widgets/post_tile.dart';
import 'create_post_page.dart';
import 'favorites_page.dart';
import 'post_details_page.dart';

/// Главный экран. Только отображает PostsState и передаёт действия
/// пользователя в PostsCubit — запросов и бизнес-логики здесь нет.
class PostsPage extends StatefulWidget {
  const PostsPage({super.key});

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      context.read<PostsCubit>().loadNextPage();
    }
  }

  void _openDetails(Post post) =>
      Navigator.push(context, PostDetailsPage.route(post));

  Future<void> _openCreate() async {
    final cubit = context.read<PostsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final created = await Navigator.push<Post>(context, CreatePostPage.route());
    if (created == null) return;
    final failure = await cubit.addCreatedPost(created);
    messenger.showSnackBar(SnackBar(
      content: Text(failure?.message ??
          'Пост добавлен в список с пометкой «создан локально»'),
    ));
  }

  Future<void> _resetFilters() async {
    // Сначала убираем фокус: иначе клавиатура может вернуть набранный текст.
    FocusManager.instance.primaryFocus?.unfocus();
    _searchController.clear();
    await context.read<PostsCubit>().resetFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Explorer'),
        actions: [
          BlocBuilder<FavoritesCubit, FavoritesState>(
            buildWhen: (a, b) => a.favorites.length != b.favorites.length,
            builder: (context, state) => IconButton(
              tooltip: 'Избранное',
              onPressed: () =>
                  Navigator.push(context, FavoritesPage.route()),
              icon: Badge(
                isLabelVisible: state.favorites.isNotEmpty,
                label: Text('${state.favorites.length}'),
                child: const Icon(Icons.star_outline),
              ),
            ),
          ),
          BlocBuilder<PostsCubit, PostsState>(
            buildWhen: (a, b) => a.filter.ascending != b.filter.ascending,
            builder: (context, state) => IconButton(
              tooltip: state.filter.ascending
                  ? 'Сортировка по ID: по возрастанию'
                  : 'Сортировка по ID: по убыванию',
              icon: Icon(state.filter.ascending
                  ? Icons.arrow_upward
                  : Icons.arrow_downward),
              onPressed: context.read<PostsCubit>().toggleSort,
            ),
          ),
          IconButton(
            tooltip: 'Сбросить фильтры',
            icon: const Icon(Icons.filter_alt_off),
            onPressed: _resetFilters,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('Новый пост'),
      ),
      body: Column(
        children: [
          FiltersBar(searchController: _searchController),
          BlocBuilder<PostsCubit, PostsState>(
            buildWhen: (a, b) =>
                a.isFromCache != b.isFromCache ||
                a.cachedAt != b.cachedAt ||
                a.failure != b.failure ||
                a.status != b.status,
            builder: (context, state) {
              final showBanner = state.status == ListStatus.success &&
                  (state.isFromCache || state.failure != null);
              if (!showBanner) return const SizedBox.shrink();
              return CacheBanner(
                savedAt: state.cachedAt,
                error: state.failure?.message,
                isUpdating: state.failure == null,
              );
            },
          ),
          Expanded(
            child: BlocBuilder<PostsCubit, PostsState>(
              builder: (context, state) => _buildBody(context, state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, PostsState state) {
    final cubit = context.read<PostsCubit>();

    switch (state.status) {
      case ListStatus.initial:
      case ListStatus.loading:
        return const LoadingView();
      case ListStatus.failure:
        return RefreshableBox(
          onRefresh: cubit.refresh,
          child: ErrorView(
            message: state.failure?.message ?? 'Не удалось загрузить посты',
            onRetry: cubit.loadFirstPage,
          ),
        );
      case ListStatus.empty:
        return RefreshableBox(
          onRefresh: cubit.refresh,
          child: const EmptyView(
            message: 'Постов пока нет. Потяните вниз, чтобы обновить',
            icon: Icons.inbox_outlined,
          ),
        );
      case ListStatus.success:
        break;
    }

    if (state.nothingFound) {
      return RefreshableBox(
        onRefresh: cubit.refresh,
        child: EmptyView(
          message: state.filter.isSearching
              ? 'Среди загруженных постов ничего не найдено '
                  'по запросу «${state.filter.query.trim()}»'
              : 'У этого автора постов нет',
          onAction: state.filter.isActive ? _resetFilters : null,
        ),
      );
    }

    final local = state.visibleLocalPosts;
    final posts = state.visiblePosts;
    final itemCount = local.length + posts.length + 1; // +1 — футер

    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 88),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          final Post post;
          if (index < local.length) {
            post = local[index];
          } else if (index - local.length < posts.length) {
            post = posts[index - local.length];
          } else {
            return ListFooter(state: state);
          }
          return PostTile(
            key: ValueKey(post.id),
            post: post,
            authorName: state.authorName(post.userId),
            onTap: () => _openDetails(post),
          );
        },
      ),
    );
  }
}
