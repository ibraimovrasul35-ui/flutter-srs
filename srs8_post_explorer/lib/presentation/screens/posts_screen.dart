import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';
import '../state/posts_cubit.dart';
import '../widgets/post_tile.dart';
import '../widgets/state_views.dart';
import 'create_post_screen.dart';
import 'post_details_screen.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
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

  void _openDetails(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostDetailsScreen(post: post)),
    );
  }

  Future<void> _openCreate() async {
    final cubit = context.read<PostsCubit>();
    final created = await Navigator.push<Post>(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
    if (created != null) {
      await cubit.addCreatedPost(created);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Пост добавлен в список с пометкой «создан локально»'),
      ));
    }
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
          BlocBuilder<PostsCubit, PostsState>(
            buildWhen: (a, b) => a.sortAscending != b.sortAscending,
            builder: (context, state) => IconButton(
              tooltip: state.sortAscending
                  ? 'Сортировка по ID: по возрастанию'
                  : 'Сортировка по ID: по убыванию',
              icon: Icon(state.sortAscending
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
          _FiltersBar(searchController: _searchController),
          BlocBuilder<PostsCubit, PostsState>(
            buildWhen: (a, b) =>
                a.isFromCache != b.isFromCache ||
                a.cachedAt != b.cachedAt ||
                a.errorMessage != b.errorMessage ||
                a.status != b.status,
            builder: (context, state) {
              if (!state.isFromCache || state.status != ListStatus.success) {
                return const SizedBox.shrink();
              }
              return CacheBanner(
                savedAt: state.cachedAt,
                error: state.errorMessage,
                isUpdating: state.errorMessage == null,
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
        return const Center(child: CircularProgressIndicator());
      case ListStatus.failure:
        return ErrorView(
          message: state.errorMessage ?? 'Не удалось загрузить посты',
          onRetry: cubit.loadFirstPage,
        );
      case ListStatus.success:
        break;
    }

    final local = state.visibleLocalPosts;
    final posts = state.visiblePosts;

    if (state.isEmpty) {
      return RefreshIndicator(
        onRefresh: cubit.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 300,
              child: EmptyView(
                message: state.isSearching
                    ? 'Среди загруженных постов ничего не найдено '
                        'по запросу «${state.query.trim()}»'
                    : 'Постов нет',
                onReset: state.hasActiveFilters ? _resetFilters : null,
              ),
            ),
          ],
        ),
      );
    }

    final itemCount = local.length + posts.length + 1; // +1 — футер
    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 88),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index < local.length) {
            final post = local[index];
            return PostTile(
              post: post,
              authorName: state.authorName(post.userId),
              onTap: () => _openDetails(post),
            );
          }
          final i = index - local.length;
          if (i < posts.length) {
            final post = posts[i];
            return PostTile(
              key: ValueKey(post.id),
              post: post,
              authorName: state.authorName(post.userId),
              onTap: () => _openDetails(post),
            );
          }
          return _ListFooter(state: state);
        },
      ),
    );
  }
}

/// Поиск, фильтр по автору и подсказка, где идёт поиск.
class _FiltersBar extends StatelessWidget {
  final TextEditingController searchController;

  const _FiltersBar({required this.searchController});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PostsCubit>();
    return BlocBuilder<PostsCubit, PostsState>(
      buildWhen: (a, b) =>
          a.users != b.users ||
          a.selectedUserId != b.selectedUserId ||
          a.posts.length != b.posts.length ||
          a.query != b.query,
      builder: (context, state) {
        final authorIds = state.users.isNotEmpty
            ? state.users.map((u) => u.id).toList()
            : List.generate(10, (i) => i + 1);

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: searchController,
                onChanged: cubit.search,
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search),
                  labelText: 'Поиск по заголовку',
                  helperMaxLines: 2,
                  helperText:
                      'Ищем среди загруженных постов (${state.posts.length}), '
                      'а не по всему серверу',
                  border: const OutlineInputBorder(),
                  suffixIcon: state.query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            searchController.clear();
                            cubit.search('');
                          },
                        ),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                initialValue: state.selectedUserId,
                key: ValueKey(state.selectedUserId),
                isExpanded: true,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Автор',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Все посты'),
                  ),
                  for (final id in authorIds)
                    DropdownMenuItem<int?>(
                      value: id,
                      child: Text('${state.authorName(id)} (userId $id)',
                          overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: cubit.selectAuthor,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Низ списка: индикатор подгрузки, ошибка с повтором или конец списка.
class _ListFooter extends StatelessWidget {
  final PostsState state;

  const _ListFooter({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PostsCubit>();

    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(state.loadMoreError!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: cubit.loadNextPage,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить загрузку страницы'),
            ),
          ],
        ),
      );
    }
    if (!state.hasMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('Больше постов нет')),
      );
    }
    // Если страница короткая и прокрутки нет — даём загрузить вручную.
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Center(
        child: TextButton(
          onPressed: cubit.loadNextPage,
          child: Text(
              'Загрузить ещё (страница ${state.page + 1} по ${PostRepository.pageSize})'),
        ),
      ),
    );
  }
}
