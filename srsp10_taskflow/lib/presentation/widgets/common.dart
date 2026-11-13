import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/database/app_database.dart';
import '../../models/enums.dart';
import '../../state/current_user_cubit.dart';

/// Показывает ошибку действия или сообщение об успехе.
void showResult(BuildContext context, String? error, {String? success}) {
  if (!context.mounted) return;
  final text = error ?? success;
  if (text == null) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error != null
            ? Theme.of(context).colorScheme.error
            : null,
      ),
    );
}

/// Дожидается действия Cubit'а и показывает его результат.
Future<void> showActionResult(
  BuildContext context,
  Future<String?> action, {
  String? success,
}) async {
  final error = await action;
  if (!context.mounted) return;
  showResult(context, error, success: success);
}

/// ID пользователя, от имени которого работает приложение.
int? currentUserId(BuildContext context) =>
    context.read<CurrentUserCubit>().state.user?.id;

/// Как [currentUserId], но с сообщением, если пользователей ещё нет.
int? requireCurrentUser(BuildContext context) {
  final id = currentUserId(context);
  if (id == null) {
    showResult(context, 'Сначала создайте пользователя на вкладке «Люди»');
  }
  return id;
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String action = 'Удалить',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return result ?? false;
}

Color statusColor(TaskStatus status) => switch (status) {
  TaskStatus.todo => Colors.blueGrey,
  TaskStatus.inProgress => Colors.blue,
  TaskStatus.done => Colors.green,
  TaskStatus.cancelled => Colors.grey,
};

Color priorityColor(TaskPriority priority) => switch (priority) {
  TaskPriority.low => Colors.teal,
  TaskPriority.medium => Colors.amber.shade800,
  TaskPriority.high => Colors.deepOrange,
  TaskPriority.critical => Colors.red.shade700,
};

/// Небольшая цветная метка (статус, приоритет, роль).
class Tag extends StatelessWidget {
  const Tag(this.label, this.color, {super.key, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusTag extends StatelessWidget {
  const StatusTag(this.status, {super.key});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) => Tag(status.label, statusColor(status));
}

class PriorityTag extends StatelessWidget {
  const PriorityTag(this.priority, {super.key});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) =>
      Tag(priority.label, priorityColor(priority), icon: Icons.flag);
}

class EmptyView extends StatelessWidget {
  const EmptyView(this.text, {super.key, this.icon = Icons.inbox_outlined});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar(this.name, {super.key, this.radius = 18});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.primaryContainer,
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: TextStyle(
          color: colors.onPrimaryContainer,
          fontSize: radius * 0.9,
        ),
      ),
    );
  }
}

/// Диалог выбора пользователя с поиском (пользователей может быть 1000+).
Future<User?> pickUser(
  BuildContext context,
  List<User> users, {
  String title = 'Выберите пользователя',
}) {
  return showDialog<User>(
    context: context,
    builder: (context) => _UserPickerDialog(users: users, title: title),
  );
}

class _UserPickerDialog extends StatefulWidget {
  const _UserPickerDialog({required this.users, required this.title});

  final List<User> users;
  final String title;

  @override
  State<_UserPickerDialog> createState() => _UserPickerDialogState();
}

class _UserPickerDialogState extends State<_UserPickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final users = widget.users
        .where(
          (u) =>
              u.name.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q),
        )
        .toList();
    return AlertDialog(
      title: Text(widget.title),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: 400,
        height: 420,
        child: Column(
          children: [
            TextField(
              autofocus: false,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Имя или email',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: users.isEmpty
                  ? const EmptyView('Никого не найдено')
                  : ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, i) => ListTile(
                        leading: UserAvatar(users[i].name),
                        title: Text(users[i].name),
                        subtitle: Text(users[i].email),
                        onTap: () => Navigator.pop(context, users[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
      ],
    );
  }
}

/// Выбор даты с возможностью очистить значение.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? firstDate;

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? 'Не указана'
        : '${value!.day.toString().padLeft(2, '0')}.'
              '${value!.month.toString().padLeft(2, '0')}.${value!.year}';
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: value == null
            ? const Icon(Icons.calendar_today)
            : IconButton(
                tooltip: 'Очистить',
                icon: const Icon(Icons.clear),
                onPressed: () => onChanged(null),
              ),
      ),
      child: InkWell(
        onTap: () async {
          final now = DateTime.now();
          final first = firstDate ?? DateTime(now.year - 1);
          var initial = value ?? now;
          if (initial.isBefore(first)) initial = first;
          final picked = await showDatePicker(
            context: context,
            initialDate: initial,
            firstDate: first,
            lastDate: DateTime(now.year + 5),
          );
          if (picked != null) onChanged(picked);
        },
        child: Text(text),
      ),
    );
  }
}
