import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/formatters.dart';
import '../../data/repositories/attachment_repository.dart';
import '../../data/repositories/comment_repository.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../models/enums.dart';
import '../../models/views.dart';
import '../../state/current_user_cubit.dart';
import '../../state/task_details_cubit.dart';
import '../widgets/common.dart';
import 'task_form_screen.dart';

class TaskDetailsScreen extends StatelessWidget {
  const TaskDetailsScreen({super.key, required this.taskId});

  final int taskId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TaskDetailsCubit(
        taskId: taskId,
        tasks: context.read<TaskRepository>(),
        comments: context.read<CommentRepository>(),
        attachments: context.read<AttachmentRepository>(),
        projects: context.read<ProjectRepository>(),
      ),
      child: const _TaskDetailsView(),
    );
  }
}

class _TaskDetailsView extends StatelessWidget {
  const _TaskDetailsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskDetailsCubit, TaskDetailsState>(
      builder: (context, state) {
        final view = state.task;
        if (!state.loaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (view == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyView('Задача удалена', icon: Icons.delete_outline),
          );
        }
        final inTrash = view.task.deletedAt != null;
        final cubit = context.read<TaskDetailsCubit>();
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(view.projectName),
              actions: [
                if (!inTrash) ...[
                  IconButton(
                    tooltip: 'Редактировать',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TaskFormScreen.edit(task: view.task),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'В корзину',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final error = await cubit.moveToTrash();
                      if (!context.mounted) return;
                      showResult(context, error, success: 'Задача в корзине');
                      if (error == null) Navigator.of(context).pop();
                    },
                  ),
                ],
              ],
            ),
            body: NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverToBoxAdapter(child: _Header(state: state)),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabsHeader(
                    TabBar(
                      tabs: [
                        Tab(text: 'Комментарии (${state.comments.length})'),
                        Tab(text: 'Файлы (${state.attachments.length})'),
                        const Tab(text: 'История'),
                      ],
                    ),
                    Theme.of(context).colorScheme.surface,
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  _CommentsTab(state: state, readOnly: inTrash),
                  _AttachmentsTab(state: state, readOnly: inTrash),
                  _HistoryTab(history: state.history),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final TaskDetailsState state;

  @override
  Widget build(BuildContext context) {
    final view = state.task!;
    final task = view.task;
    final cubit = context.read<TaskDetailsCubit>();
    final theme = Theme.of(context);
    final inTrash = task.deletedAt != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (inTrash)
            Card(
              color: theme.colorScheme.errorContainer,
              child: ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Задача в корзине'),
                trailing: TextButton(
                  onPressed: () async => showActionResult(
                    context,
                    cubit.restore(),
                    success: 'Задача восстановлена',
                  ),
                  child: const Text('Восстановить'),
                ),
              ),
            ),
          Text(task.title, style: theme.textTheme.headlineSmall),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(task.description),
          ],
          const SizedBox(height: 16),
          Text('Статус', style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in TaskStatus.values)
                ChoiceChip(
                  label: Text(s.label),
                  selected: task.status == s,
                  selectedColor: statusColor(s).withValues(alpha: 0.2),
                  onSelected: inTrash || task.status == s
                      ? null
                      : (_) async {
                          final actor = requireCurrentUser(context);
                          if (actor == null) return;
                          showActionResult(
                            context,
                            cubit.changeStatus(s, actor),
                          );
                        },
                ),
            ],
          ),
          if (state.canUndo && !inTrash)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.undo),
                label: const Text('Отменить последнее изменение статуса'),
                onPressed: () async {
                  final actor = requireCurrentUser(context);
                  if (actor == null) return;
                  showActionResult(
                    context,
                    cubit.undo(actor),
                    success: 'Статус возвращён',
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: UserAvatar(view.assignee?.name ?? '?'),
                  title: Text(view.assignee?.name ?? 'Не назначен'),
                  subtitle: const Text('Исполнитель'),
                  trailing: inTrash
                      ? null
                      : TextButton(
                          onPressed: () => _reassign(context),
                          child: const Text('Изменить'),
                        ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.flag,
                    color: priorityColor(task.priority),
                  ),
                  title: Text(task.priority.label),
                  subtitle: const Text('Приоритет'),
                  trailing: inTrash
                      ? null
                      : PopupMenuButton<TaskPriority>(
                          initialValue: task.priority,
                          onSelected: (p) async => showActionResult(
                            context,
                            cubit.changePriority(p),
                          ),
                          itemBuilder: (_) => [
                            for (final p in TaskPriority.values)
                              PopupMenuItem(value: p, child: Text(p.label)),
                          ],
                        ),
                ),
                ListTile(
                  leading: Icon(
                    view.isOverdue ? Icons.warning_amber : Icons.event,
                    color: view.isOverdue ? theme.colorScheme.error : null,
                  ),
                  title: Text(
                    formatDate(task.deadline),
                    style: view.isOverdue
                        ? TextStyle(color: theme.colorScheme.error)
                        : null,
                  ),
                  subtitle: Text(
                    view.isOverdue ? 'Дедлайн просрочен' : 'Дедлайн',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Создана ${formatDateTime(task.createdAt)} · '
            'изменена ${formatDateTime(task.updatedAt)}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _reassign(BuildContext context) async {
    final cubit = context.read<TaskDetailsCubit>();
    final members = state.members;
    final choice = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Назначить участника проекта')),
            ListTile(
              leading: const Icon(Icons.person_off_outlined),
              title: const Text('Без исполнителя'),
              onTap: () => Navigator.pop(context, -1),
            ),
            for (final m in members)
              ListTile(
                leading: UserAvatar(m.user.name),
                title: Text(m.user.name),
                subtitle: Text(m.role.label),
                onTap: () => Navigator.pop(context, m.user.id),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    final actor = requireCurrentUser(context);
    if (actor == null) return;
    showActionResult(
      context,
      cubit.reassign(choice == -1 ? null : choice, actor),
      success: 'Исполнитель изменён',
    );
  }
}

class _TabsHeader extends SliverPersistentHeaderDelegate {
  _TabsHeader(this.tabBar, this.color);

  final TabBar tabBar;
  final Color color;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      ColoredBox(color: color, child: tabBar);

  @override
  bool shouldRebuild(_TabsHeader old) => old.tabBar != tabBar;
}

class _CommentsTab extends StatefulWidget {
  const _CommentsTab({required this.state, required this.readOnly});

  final TaskDetailsState state;
  final bool readOnly;

  @override
  State<_CommentsTab> createState() => _CommentsTabState();
}

class _CommentsTabState extends State<_CommentsTab> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final actor = requireCurrentUser(context);
    if (actor == null) return;
    final error = await context.read<TaskDetailsCubit>().addComment(
      _controller.text,
      actor,
    );
    if (!mounted) return;
    if (error == null) {
      _controller.clear();
    } else {
      showResult(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final comments = widget.state.comments;
    final me = context.select((CurrentUserCubit c) => c.state.user?.id);
    return Column(
      children: [
        Expanded(
          child: comments.isEmpty
              ? const EmptyView(
                  'Комментариев нет',
                  icon: Icons.chat_bubble_outline,
                )
              : ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, i) => _CommentTile(
                    view: comments[i],
                    canDelete: comments[i].author.id == me && !widget.readOnly,
                  ),
                ),
        ),
        if (!widget.readOnly)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Написать комментарий',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Отправить',
                    icon: const Icon(Icons.send),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.view, required this.canDelete});

  final CommentView view;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: UserAvatar(view.author.name),
      title: Text(view.author.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(view.comment.body),
          Text(
            formatDateTime(view.comment.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      trailing: canDelete
          ? IconButton(
              tooltip: 'Удалить',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final me = currentUserId(context);
                if (me == null) return;
                showActionResult(
                  context,
                  context.read<TaskDetailsCubit>().deleteComment(
                    view.comment.id,
                    me,
                  ),
                );
              },
            )
          : null,
    );
  }
}

class _AttachmentsTab extends StatelessWidget {
  const _AttachmentsTab({required this.state, required this.readOnly});

  final TaskDetailsState state;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TaskDetailsCubit>();
    final files = state.attachments;
    return ListView(
      children: [
        if (!readOnly)
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: const Text('Прикрепить файл'),
              onPressed: () async {
                final file = (await FilePicker.pickFiles()).firstOrNull;
                if (file == null || file.path == null || !context.mounted) {
                  return;
                }
                showActionResult(
                  context,
                  cubit.addAttachment(file.name, file.path!),
                  success: 'Файл прикреплён',
                );
              },
            ),
          ),
        if (files.isEmpty)
          const EmptyView('Вложений нет', icon: Icons.folder_open)
        else
          for (final a in files)
            ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: Text(a.fileName),
              subtitle: Text(
                '${a.filePath}\n${formatDateTime(a.addedAt)}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              isThreeLine: true,
              trailing: readOnly
                  ? null
                  : IconButton(
                      tooltip: 'Открепить',
                      icon: const Icon(Icons.close),
                      onPressed: () async => showActionResult(
                        context,
                        cubit.deleteAttachment(a.id),
                      ),
                    ),
            ),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.history});

  final List<HistoryView> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const EmptyView('История пуста', icon: Icons.history);
    }
    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, i) {
        final h = history[i].entry;
        final who = history[i].user?.name ?? 'Неизвестно';
        final change = switch (h.kind) {
          HistoryKind.created => 'Задача создана',
          HistoryKind.assignee => 'Исполнитель: ${h.details ?? ''}',
          _ => '${h.oldStatus?.label ?? '—'} → ${h.newStatus?.label ?? '—'}',
        };
        return ListTile(
          leading: Icon(switch (h.kind) {
            HistoryKind.created => Icons.add_circle_outline,
            HistoryKind.status => Icons.swap_horiz,
            HistoryKind.assignee => Icons.person_outline,
            HistoryKind.undo => Icons.undo,
          }),
          title: Text(
            change,
            style: h.undone
                ? const TextStyle(decoration: TextDecoration.lineThrough)
                : null,
          ),
          subtitle: Text(
            '${h.kind.label}${h.undone ? ' (отменено)' : ''} · $who · '
            '${formatDateTime(h.changedAt)}',
          ),
        );
      },
    );
  }
}
