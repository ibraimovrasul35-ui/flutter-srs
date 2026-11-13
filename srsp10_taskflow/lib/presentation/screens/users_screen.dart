import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/formatters.dart';
import '../../data/database/app_database.dart';
import '../../models/task_filter.dart';
import '../../state/current_user_cubit.dart';
import '../../state/entity_cubits.dart';
import '../../state/load_state.dart';
import '../widgets/common.dart';
import '../widgets/task_list_panel.dart';

/// Пользователи: создание, редактирование, удаление.
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final currentId = context.select((CurrentUserCubit c) => c.state.user?.id);
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Поиск по имени или email',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: BlocBuilder<UsersCubit, LoadState<List<User>>>(
              builder: (context, state) {
                if (state.error != null) return EmptyView(state.error!);
                final all = state.data;
                if (all == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                final users = all
                    .where(
                      (u) =>
                          u.name.toLowerCase().contains(_query) ||
                          u.email.toLowerCase().contains(_query),
                    )
                    .toList();
                if (users.isEmpty) {
                  return EmptyView(
                    all.isEmpty
                        ? 'Пользователей пока нет'
                        : 'Никого не найдено',
                    icon: Icons.group_outlined,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: users.length,
                  itemBuilder: (context, i) => _UserTile(
                    user: users[i],
                    isCurrent: users[i].id == currentId,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-user',
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Пользователь'),
        onPressed: () => showUserDialog(context),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.isCurrent});

  final User user;
  final bool isCurrent;

  Future<void> _delete(BuildContext context) async {
    final ok = await confirm(
      context,
      title: 'Удалить пользователя?',
      message:
          '${user.name} будет удалён(а) из всех проектов. '
          'Удалить нельзя, пока у пользователя есть незавершённые задачи.',
    );
    if (!ok || !context.mounted) return;
    final error = await context.read<UsersCubit>().delete(user.id);
    if (!context.mounted) return;
    showResult(context, error, success: 'Пользователь удалён');
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: UserAvatar(user.name),
      title: Row(
        children: [
          Flexible(child: Text(user.name, overflow: TextOverflow.ellipsis)),
          if (isCurrent) ...[
            const SizedBox(width: 8),
            Tag('это вы', Theme.of(context).colorScheme.primary),
          ],
        ],
      ),
      subtitle: Text('${user.email}\nс ${formatDate(user.registeredAt)}'),
      isThreeLine: true,
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => UserTasksScreen(user: user))),
      trailing: PopupMenuButton<String>(
        onSelected: (action) => switch (action) {
          'current' => context.read<CurrentUserCubit>().select(user),
          'edit' => showUserDialog(context, user: user),
          _ => _delete(context),
        },
        itemBuilder: (context) => [
          if (!isCurrent)
            const PopupMenuItem(
              value: 'current',
              child: Text('Работать от имени'),
            ),
          const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
          const PopupMenuItem(value: 'delete', child: Text('Удалить')),
        ],
      ),
    );
  }
}

/// Диалог создания или редактирования пользователя.
Future<void> showUserDialog(BuildContext context, {User? user}) {
  return showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: context.read<UsersCubit>(),
      child: _UserDialog(user: user),
    ),
  );
}

class _UserDialog extends StatefulWidget {
  const _UserDialog({this.user});

  final User? user;

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user?.name);
  late final _email = TextEditingController(text: widget.user?.email);
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<UsersCubit>();
    setState(() => _saving = true);
    final user = widget.user;
    final error = user == null
        ? await cubit.create(_name.text, _email.text)
        : await cubit.update(user.id, _name.text, _email.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context);
    } else {
      // Ошибку (например, занятый email) показываем прямо в диалоге.
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.user == null ? 'Новый пользователь' : 'Редактирование',
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Имя *'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v ?? '').trim().isEmpty ? 'Введите имя' : null,
            ),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email *'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Введите email' : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

/// Задачи одного пользователя по всем проектам.
class UserTasksScreen extends StatelessWidget {
  const UserTasksScreen({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Задачи: ${user.name}')),
      body: TaskListPanel(
        filter: TaskFilter(assigneeId: user.id),
        emptyText: 'У пользователя нет задач',
      ),
    );
  }
}
