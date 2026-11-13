import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/formatters.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/project_repository.dart';
import '../../models/enums.dart';
import '../../models/task_filter.dart';
import '../../models/views.dart';
import '../../state/current_user_cubit.dart';
import '../../state/entity_cubits.dart';
import '../../state/project_details_cubit.dart';
import '../widgets/common.dart';
import '../widgets/task_list_panel.dart';
import 'project_form_screen.dart';
import 'projects_screen.dart';
import 'task_form_screen.dart';

/// Проект: задачи и участники.
class ProjectDetailsScreen extends StatelessWidget {
  const ProjectDetailsScreen({super.key, required this.projectId});

  final int projectId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ProjectDetailsCubit(context.read<ProjectRepository>(), projectId),
      child: const _ProjectDetailsView(),
    );
  }
}

class _ProjectDetailsView extends StatelessWidget {
  const _ProjectDetailsView();

  Future<void> _delete(BuildContext context, Project project) async {
    final ok = await confirm(
      context,
      title: 'Удалить проект?',
      message:
          '«${project.name}» будет удалён вместе со всеми задачами, '
          'комментариями, вложениями и историей.',
    );
    if (!ok || !context.mounted) return;
    final navigator = Navigator.of(context);
    final error = await context.read<ProjectsCubit>().delete(project.id);
    if (!context.mounted) return;
    showResult(context, error, success: 'Проект удалён');
    if (error == null) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectDetailsCubit, ProjectDetailsState>(
      builder: (context, state) {
        final project = state.project;
        if (!state.loaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (project == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyView('Проект не найден или удалён'),
          );
        }
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(project.name),
              actions: [
                IconButton(
                  tooltip: 'Редактировать',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProjectFormScreen(project: project),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Удалить проект',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context, project),
                ),
              ],
              bottom: TabBar(
                tabs: [
                  const Tab(text: 'Задачи'),
                  Tab(text: 'Участники (${state.members.length})'),
                ],
              ),
            ),
            body: Column(
              children: [
                _ProjectHeader(project: project),
                Expanded(
                  child: TabBarView(
                    children: [
                      TaskListPanel(
                        filter: TaskFilter(projectId: project.id),
                        showProject: false,
                        emptyText: 'В проекте пока нет задач',
                      ),
                      _MembersTab(members: state.members),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'new-task-${project.id}',
              icon: const Icon(Icons.add_task),
              label: const Text('Задача'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TaskFormScreen.create(projectId: project.id),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Tag(project.status.label, projectStatusColor(project.status)),
              Text(
                'Создан ${formatDate(project.createdAt)} · '
                'окончание ${formatDate(project.endDate)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          if (project.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(project.description, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _MembersTab extends StatelessWidget {
  const _MembersTab({required this.members});

  final List<MemberView> members;

  Future<void> _add(BuildContext context) async {
    final cubit = context.read<ProjectDetailsCubit>();
    final memberIds = members.map((m) => m.user.id).toSet();
    final candidates = context
        .read<CurrentUserCubit>()
        .state
        .users
        .where((u) => !memberIds.contains(u.id))
        .toList();
    if (candidates.isEmpty) {
      showResult(context, 'Все пользователи уже в проекте');
      return;
    }
    final user = await pickUser(
      context,
      candidates,
      title: 'Добавить участника',
    );
    if (user == null || !context.mounted) return;
    final role = await _pickRole(context, MemberRole.member);
    if (role == null || !context.mounted) return;
    showActionResult(
      context,
      cubit.addMember(user.id, role),
      success: '${user.name} добавлен(а) в проект',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        ListTile(
          leading: const Icon(Icons.person_add_alt),
          title: const Text('Добавить участника'),
          onTap: () => _add(context),
        ),
        const Divider(height: 1),
        if (members.isEmpty)
          const EmptyView('В проекте нет участников', icon: Icons.group_off),
        for (final m in members) _MemberTile(member: m),
      ],
    );
  }
}

Future<MemberRole?> _pickRole(BuildContext context, MemberRole current) {
  return showDialog<MemberRole>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Роль в проекте'),
      children: [
        for (final r in MemberRole.values)
          ListTile(
            leading: Icon(
              r == current
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            title: Text(r.label),
            onTap: () => Navigator.pop(context, r),
          ),
      ],
    ),
  );
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final MemberView member;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProjectDetailsCubit>();
    final user = member.user;
    return ListTile(
      leading: UserAvatar(user.name),
      title: Text(user.name),
      subtitle: Text(user.email),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ActionChip(
            label: Text(member.role.label),
            onPressed: () async {
              final role = await _pickRole(context, member.role);
              if (role == null || role == member.role) return;
              if (!context.mounted) return;
              showActionResult(
                context,
                cubit.changeRole(user.id, role),
                success: 'Роль изменена',
              );
            },
          ),
          IconButton(
            tooltip: 'Убрать из проекта',
            icon: const Icon(Icons.person_remove_outlined),
            onPressed: () async {
              final ok = await confirm(
                context,
                title: 'Убрать участника?',
                message:
                    '${user.name} больше не сможет быть исполнителем '
                    'задач этого проекта.',
                action: 'Убрать',
              );
              if (!ok || !context.mounted) return;
              showActionResult(
                context,
                cubit.removeMember(user.id),
                success: 'Участник удалён из проекта',
              );
            },
          ),
        ],
      ),
    );
  }
}
