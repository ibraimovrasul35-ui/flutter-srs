import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/formatters.dart';
import '../../data/repositories/task_repository.dart';
import '../../models/enums.dart';
import '../../models/task_filter.dart';
import '../../models/views.dart';
import '../../state/current_user_cubit.dart';
import '../../state/task_list_cubit.dart';
import '../screens/task_details_screen.dart';
import 'common.dart';

/// Список задач с поиском, фильтрами, сортировкой и пагинацией.
/// [filter] задаёт неизменяемую часть (проект, исполнитель или корзина).
class TaskListPanel extends StatelessWidget {
  const TaskListPanel({
    super.key,
    required this.filter,
    this.showProject = true,
    this.emptyText = 'Задач пока нет',
  });

  final TaskFilter filter;
  final bool showProject;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(filter),
      create: (context) =>
          TaskListCubit(context.read<TaskRepository>(), filter),
      child: _TaskListBody(
        fixedAssignee: filter.assigneeId != null,
        trash: filter.deletedOnly,
        showProject: showProject,
        emptyText: emptyText,
      ),
    );
  }
}

class _TaskListBody extends StatelessWidget {
  const _TaskListBody({
    required this.fixedAssignee,
    required this.trash,
    required this.showProject,
    required this.emptyText,
  });

  final bool fixedAssignee;
  final bool trash;
  final bool showProject;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TaskListCubit>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Поиск по названию и описанию',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: cubit.search,
          ),
        ),
        _FilterBar(fixedAssignee: fixedAssignee),
        const Divider(height: 1),
        Expanded(
          child: BlocBuilder<TaskListCubit, TaskListState>(
            builder: (context, state) {
              if (state.loading && state.tasks.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.tasks.isEmpty) {
                return EmptyView(
                  state.filter.query.isNotEmpty ||
                          state.filter.status != null ||
                          state.filter.priority != null
                      ? 'Ничего не найдено'
                      : emptyText,
                  icon: Icons.task_alt,
                );
              }
              return NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.pixels > n.metrics.maxScrollExtent - 300) {
                    cubit.loadMore();
                  }
                  return false;
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: state.tasks.length + 1,
                  itemBuilder: (context, i) {
                    if (i == state.tasks.length) {
                      return _Footer(state: state);
                    }
                    final view = state.tasks[i];
                    return TaskTile(
                      view: view,
                      showProject: showProject,
                      trailing: trash ? _TrashActions(view: view) : null,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state});

  final TaskListState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (state.hasMore) const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text(
            'Показано ${state.tasks.length} из ${state.total}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.fixedAssignee});

  final bool fixedAssignee;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TaskListCubit>();
    final filter = context.select((TaskListCubit c) => c.state.filter);
    final users = context.select((CurrentUserCubit c) => c.state.users);
    final assignee = users.where((u) => u.id == filter.assigneeId).firstOrNull;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _MenuChip<TaskStatus>(
            label: 'Статус',
            value: filter.status,
            values: TaskStatus.values,
            labelOf: (s) => s.label,
            onSelected: cubit.setStatus,
          ),
          const SizedBox(width: 8),
          _MenuChip<TaskPriority>(
            label: 'Приоритет',
            value: filter.priority,
            values: TaskPriority.values,
            labelOf: (p) => p.label,
            onSelected: cubit.setPriority,
          ),
          if (!fixedAssignee) ...[
            const SizedBox(width: 8),
            InputChip(
              avatar: const Icon(Icons.person_outline, size: 18),
              label: Text(assignee?.name ?? 'Исполнитель'),
              selected: assignee != null,
              onPressed: () async {
                final user = await pickUser(
                  context,
                  users,
                  title: 'Фильтр по исполнителю',
                );
                if (user != null) cubit.setAssignee(user.id);
              },
              onDeleted: assignee == null
                  ? null
                  : () => cubit.setAssignee(null),
            ),
          ],
          const SizedBox(width: 8),
          PopupMenuButton<TaskSort>(
            initialValue: filter.sort,
            onSelected: cubit.setSort,
            itemBuilder: (context) => [
              for (final s in TaskSort.values)
                PopupMenuItem(value: s, child: Text(s.label)),
            ],
            child: Chip(
              avatar: const Icon(Icons.sort, size: 18),
              label: Text(filter.sort.label),
            ),
          ),
        ],
      ),
    );
  }
}

/// Чип-фильтр с выпадающим списком значений и пунктом «Все».
class _MenuChip<T extends Object> extends StatelessWidget {
  const _MenuChip({
    required this.label,
    required this.value,
    required this.values,
    required this.labelOf,
    required this.onSelected,
  });

  static const _all = 'all';

  final String label;
  final T? value;
  final List<T> values;
  final String Function(T) labelOf;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Object>(
      onSelected: (v) => onSelected(v == _all ? null : v as T),
      itemBuilder: (context) => [
        const PopupMenuItem(value: _all, child: Text('Все')),
        for (final v in values)
          PopupMenuItem(value: v, child: Text(labelOf(v))),
      ],
      child: Chip(
        label: Text(value == null ? label : labelOf(value as T)),
        backgroundColor: value == null
            ? null
            : Theme.of(context).colorScheme.secondaryContainer,
        avatar: const Icon(Icons.filter_list, size: 18),
      ),
    );
  }
}

class _TrashActions extends StatelessWidget {
  const _TrashActions({required this.view});

  final TaskView view;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TaskListCubit>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Восстановить',
          icon: const Icon(Icons.restore_from_trash),
          onPressed: () async => showActionResult(
            context,
            cubit.restore(view.task.id),
            success: 'Задача восстановлена',
          ),
        ),
        IconButton(
          tooltip: 'Удалить навсегда',
          icon: const Icon(Icons.delete_forever),
          onPressed: () async {
            final ok = await confirm(
              context,
              title: 'Удалить навсегда?',
              message:
                  '«${view.task.title}» будет удалена вместе с комментариями, '
                  'вложениями и историей.',
            );
            if (!ok || !context.mounted) return;
            showActionResult(
              context,
              cubit.deletePermanently(view.task.id),
              success: 'Задача удалена',
            );
          },
        ),
      ],
    );
  }
}

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.view,
    this.showProject = true,
    this.trailing,
  });

  final TaskView view;
  final bool showProject;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final task = view.task;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.outline,
    );
    return ListTile(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TaskDetailsScreen(taskId: task.id)),
      ),
      title: Text(
        task.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style:
            task.status == TaskStatus.done ||
                task.status == TaskStatus.cancelled
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [StatusTag(task.status), PriorityTag(task.priority)],
            ),
            const SizedBox(height: 4),
            Text(
              [
                if (showProject) view.projectName,
                view.assignee?.name ?? 'Без исполнителя',
              ].join(' · '),
              style: muted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      trailing:
          trailing ??
          (task.deadline == null
              ? null
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(
                      view.isOverdue ? Icons.warning_amber : Icons.event,
                      size: 18,
                      color: view.isOverdue ? theme.colorScheme.error : null,
                    ),
                    Text(
                      formatDate(task.deadline),
                      style: view.isOverdue
                          ? TextStyle(color: theme.colorScheme.error)
                          : muted,
                    ),
                  ],
                )),
    );
  }
}
