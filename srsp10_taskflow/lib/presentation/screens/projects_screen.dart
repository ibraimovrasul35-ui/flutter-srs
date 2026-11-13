import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/formatters.dart';
import '../../models/enums.dart';
import '../../models/views.dart';
import '../../state/entity_cubits.dart';
import '../../state/load_state.dart';
import '../widgets/common.dart';
import 'project_details_screen.dart';
import 'project_form_screen.dart';

/// Список проектов с прогрессом выполнения.
class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ProjectsCubit, LoadState<List<ProjectSummary>>>(
        builder: (context, state) {
          if (state.error != null) return EmptyView(state.error!);
          final projects = state.data;
          if (projects == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (projects.isEmpty) {
            return const EmptyView(
              'Проектов пока нет.\nНажмите «+», чтобы создать первый.',
              icon: Icons.folder_open,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
            itemCount: projects.length,
            itemBuilder: (context, i) => _ProjectCard(summary: projects[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-project',
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('Проект'),
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const ProjectFormScreen())),
      ),
    );
  }
}

Color projectStatusColor(ProjectStatus status) => switch (status) {
  ProjectStatus.active => Colors.blue,
  ProjectStatus.completed => Colors.green,
  ProjectStatus.archived => Colors.grey,
};

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.summary});

  final ProjectSummary summary;

  @override
  Widget build(BuildContext context) {
    final project = summary.project;
    final theme = Theme.of(context);
    final percent = (summary.progress * 100).round();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectDetailsScreen(projectId: project.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Tag(project.status.label, projectStatusColor(project.status)),
                ],
              ),
              if (project.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  project.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: summary.progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 6),
              Text(
                'Выполнено ${summary.doneTasks} из '
                '${summary.totalTasks - summary.cancelledTasks} · $percent%'
                '${project.endDate == null ? '' : ' · до ${formatDate(project.endDate)}'}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
