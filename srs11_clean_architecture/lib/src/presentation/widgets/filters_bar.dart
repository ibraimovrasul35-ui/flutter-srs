import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/posts/posts_cubit.dart';

/// Поиск, фильтр по автору и подсказка, где идёт поиск.
class FiltersBar extends StatelessWidget {
  final TextEditingController searchController;

  const FiltersBar({super.key, required this.searchController});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PostsCubit>();
    return BlocBuilder<PostsCubit, PostsState>(
      buildWhen: (a, b) =>
          a.authors != b.authors ||
          a.filter != b.filter ||
          a.posts.length != b.posts.length,
      builder: (context, state) {
        final authorIds = state.authors.isNotEmpty
            ? state.authors.map((a) => a.id).toList()
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
                  suffixIcon: state.filter.query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Очистить',
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
                initialValue: state.filter.userId,
                key: ValueKey(state.filter.userId),
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
