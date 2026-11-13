import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/dashboard_stats.dart';
import '../../models/enums.dart';
import '../../state/entity_cubits.dart';
import '../../state/load_state.dart';
import '../widgets/common.dart';

/// Статистика: общие числа, приоритеты, загрузка людей, прогресс проектов.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, LoadState<DashboardStats>>(
      builder: (context, state) {
        if (state.error != null) return EmptyView(state.error!);
        final stats = state.data;
        if (stats == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.9,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _NumberCard(
                  'Проектов',
                  stats.projects,
                  Icons.folder,
                  Colors.indigo,
                ),
                _NumberCard(
                  'Всего задач',
                  stats.totalTasks,
                  Icons.list_alt,
                  Colors.blueGrey,
                ),
                _NumberCard(
                  'Завершено',
                  stats.doneTasks,
                  Icons.check_circle,
                  Colors.green,
                ),
                _NumberCard(
                  'В работе / ожидают',
                  stats.openTasks,
                  Icons.pending_actions,
                  Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _NumberCard(
              'Просрочено',
              stats.overdueTasks,
              Icons.warning_amber,
              stats.overdueTasks > 0 ? Colors.red : Colors.grey,
            ),
            _Section(
              title: 'Задачи по приоритетам',
              child: Column(
                children: [
                  for (final p in TaskPriority.values.reversed)
                    _BarRow(
                      label: p.label,
                      value: stats.byPriority[p] ?? 0,
                      max: stats.totalTasks,
                      color: priorityColor(p),
                    ),
                ],
              ),
            ),
            _Section(
              title: 'Задачи по исполнителям',
              child: stats.byAssignee.isEmpty
                  ? const Text('Нет назначенных задач')
                  : Column(
                      children: [
                        for (final a in stats.byAssignee.take(10))
                          _BarRow(
                            label: a.name,
                            value: a.count,
                            max: stats.byAssignee.first.count,
                            color: Colors.indigo,
                          ),
                      ],
                    ),
            ),
            _Section(
              title: 'Прогресс проектов',
              child: stats.projectProgress.isEmpty
                  ? const Text('Проектов нет')
                  : Column(
                      children: [
                        for (final p in stats.projectProgress.take(15))
                          _ProgressRow(progress: p),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _NumberCard extends StatelessWidget {
  const _NumberCard(this.label, this.value, this.icon, this.color);

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Горизонтальная полоса-диаграмма.
class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  final String label;
  final int value;
  final int max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: max == 0 ? 0 : value / max,
              minHeight: 12,
              color: color,
              backgroundColor: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          SizedBox(width: 48, child: Text('$value', textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.progress});

  final ProjectProgress progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  progress.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${progress.done}/${progress.total} · '
                '${progress.percent.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress.percent / 100,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }
}
