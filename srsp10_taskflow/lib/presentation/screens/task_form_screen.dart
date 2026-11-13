import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/formatters.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../models/enums.dart';
import '../../state/task_form_cubit.dart';
import '../widgets/common.dart';

/// Создание задачи (в выбранном или заданном проекте) и её редактирование.
class TaskFormScreen extends StatelessWidget {
  const TaskFormScreen.create({super.key, this.projectId}) : task = null;
  const TaskFormScreen.edit({super.key, required Task this.task})
    : projectId = null;

  final int? projectId;
  final Task? task;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TaskFormCubit(
        context.read<TaskRepository>(),
        context.read<ProjectRepository>(),
        projectId: task?.projectId ?? projectId,
      ),
      child: _TaskForm(
        task: task,
        projectFixed: task != null || projectId != null,
      ),
    );
  }
}

class _TaskForm extends StatefulWidget {
  const _TaskForm({required this.task, required this.projectFixed});

  final Task? task;
  final bool projectFixed;

  @override
  State<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<_TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.task?.title);
  late final _description = TextEditingController(
    text: widget.task?.description,
  );
  late TaskPriority _priority = widget.task?.priority ?? TaskPriority.medium;
  late DateTime? _deadline = widget.task?.deadline;
  int? _assigneeId;

  bool get _isEdit => widget.task != null;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<TaskFormCubit>();
    final String? error;
    if (_isEdit) {
      error = await cubit.update(
        widget.task!.id,
        title: _title.text,
        description: _description.text,
        priority: _priority,
        deadline: _deadline,
      );
    } else {
      final actor = requireCurrentUser(context);
      if (actor == null) return;
      error = await cubit.create(
        title: _title.text,
        description: _description.text,
        assigneeId: _assigneeId,
        priority: _priority,
        deadline: _deadline,
        actorId: actor,
      );
    }
    if (!mounted) return;
    showResult(
      context,
      error,
      success: _isEdit ? 'Сохранено' : 'Задача создана',
    );
    if (error == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskFormCubit, TaskFormState>(
      builder: (context, state) {
        final cubit = context.read<TaskFormCubit>();
        return Scaffold(
          appBar: AppBar(
            title: Text(_isEdit ? 'Редактирование задачи' : 'Новая задача'),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (!widget.projectFixed)
                  DropdownButtonFormField<int>(
                    initialValue: state.projectId,
                    decoration: const InputDecoration(labelText: 'Проект *'),
                    items: [
                      for (final p in state.projects)
                        DropdownMenuItem(
                          value: p.id,
                          child: Text(p.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    validator: (v) => v == null ? 'Выберите проект' : null,
                    onChanged: (id) {
                      if (id == null) return;
                      setState(() => _assigneeId = null);
                      cubit.selectProject(id);
                    },
                  ),
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Название *'),
                  maxLength: 200,
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Введите название' : null,
                ),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(labelText: 'Описание'),
                  minLines: 2,
                  maxLines: 6,
                ),
                const SizedBox(height: 12),
                if (!_isEdit)
                  DropdownButtonFormField<int?>(
                    key: ValueKey(state.projectId),
                    initialValue: _assigneeId,
                    decoration: InputDecoration(
                      labelText: 'Исполнитель',
                      helperText: state.projectId == null
                          ? 'Сначала выберите проект'
                          : 'Только участники проекта',
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Не назначен'),
                      ),
                      for (final m in state.members)
                        DropdownMenuItem<int?>(
                          value: m.user.id,
                          child: Text('${m.user.name} (${m.role.label})'),
                        ),
                    ],
                    onChanged: (v) => setState(() => _assigneeId = v),
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TaskPriority>(
                  initialValue: _priority,
                  decoration: const InputDecoration(labelText: 'Приоритет'),
                  items: [
                    for (final p in TaskPriority.values)
                      DropdownMenuItem(value: p, child: Text(p.label)),
                  ],
                  onChanged: (v) => setState(() => _priority = v ?? _priority),
                ),
                const SizedBox(height: 12),
                DateField(
                  label: 'Дедлайн',
                  value: _deadline,
                  firstDate: startOfDay(DateTime.now()),
                  onChanged: (v) => setState(() => _deadline = v),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: state.saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isEdit ? 'Сохранить' : 'Создать задачу'),
                  onPressed: state.saving ? null : _save,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
