import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/task_repository.dart';
import '../../models/task_filter.dart';
import '../widgets/common.dart';
import '../widgets/task_list_panel.dart';

/// Корзина: задачи с заполненным deleted_at (Soft Delete).
class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  Future<void> _emptyTrash(BuildContext context) async {
    final ok = await confirm(
      context,
      title: 'Очистить корзину?',
      message: 'Все задачи из корзины будут удалены навсегда.',
      action: 'Очистить',
    );
    if (!ok || !context.mounted) return;
    final repository = context.read<TaskRepository>();
    String? error;
    var count = 0;
    try {
      count = await repository.emptyTrash();
    } catch (e) {
      error = 'Не удалось очистить корзину: $e';
    }
    if (!context.mounted) return;
    showResult(context, error, success: 'Удалено задач: $count');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Корзина'),
        actions: [
          IconButton(
            tooltip: 'Очистить корзину',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => _emptyTrash(context),
          ),
        ],
      ),
      body: const TaskListPanel(
        filter: TaskFilter(deletedOnly: true),
        emptyText: 'Корзина пуста',
      ),
    );
  }
}
