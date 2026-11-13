import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/database/app_database.dart';
import '../../models/enums.dart';
import '../../state/entity_cubits.dart';
import '../widgets/common.dart';

/// Создание и редактирование проекта.
class ProjectFormScreen extends StatefulWidget {
  const ProjectFormScreen({super.key, this.project});

  final Project? project;

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.project?.name);
  late final _description = TextEditingController(
    text: widget.project?.description,
  );
  late ProjectStatus _status = widget.project?.status ?? ProjectStatus.active;
  late DateTime? _endDate = widget.project?.endDate;
  bool _saving = false;

  bool get _isEdit => widget.project != null;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<ProjectsCubit>();
    final ownerId = currentUserId(context);
    setState(() => _saving = true);
    final String? error;
    if (_isEdit) {
      error = await cubit.update(
        widget.project!.id,
        name: _name.text,
        description: _description.text,
        status: _status,
        endDate: _endDate,
      );
    } else {
      error = await cubit.create(
        name: _name.text,
        description: _description.text,
        status: _status,
        endDate: _endDate,
        ownerId: ownerId,
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);
    showResult(
      context,
      error,
      success: _isEdit ? 'Сохранено' : 'Проект создан',
    );
    if (error == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Редактирование проекта' : 'Новый проект'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Название *'),
              maxLength: 120,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Введите название' : null,
            ),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Описание'),
              minLines: 2,
              maxLines: 5,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ProjectStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Статус'),
              items: [
                for (final s in ProjectStatus.values)
                  DropdownMenuItem(value: s, child: Text(s.label)),
              ],
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
            const SizedBox(height: 12),
            DateField(
              label: 'Дата окончания',
              value: _endDate,
              firstDate: widget.project?.createdAt,
              onChanged: (v) => setState(() => _endDate = v),
            ),
            if (!_isEdit) ...[
              const SizedBox(height: 12),
              Text(
                'Вы будете добавлены в проект с ролью Owner.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.check),
              label: Text(_isEdit ? 'Сохранить' : 'Создать проект'),
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
