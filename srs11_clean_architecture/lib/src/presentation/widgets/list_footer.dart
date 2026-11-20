import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/posts/posts_cubit.dart';

/// Низ списка: индикатор подгрузки, ошибка с повтором или конец списка.
class ListFooter extends StatelessWidget {
  final PostsState state;

  const ListFooter({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PostsCubit>();

    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final failure = state.loadMoreFailure;
    if (failure != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(failure.message, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: cubit.loadNextPage,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
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
          child: Text('Загрузить ещё (страница ${state.page + 1} '
              'по ${PostsCubit.pageSize})'),
        ),
      ),
    );
  }
}
