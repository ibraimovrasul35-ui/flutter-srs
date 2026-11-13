import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/task_filter.dart';
import '../../state/current_user_cubit.dart';
import '../widgets/common.dart';
import '../widgets/task_list_panel.dart';
import 'dashboard_screen.dart';
import 'performance_screen.dart';
import 'projects_screen.dart';
import 'task_form_screen.dart';
import 'trash_screen.dart';
import 'users_screen.dart';

/// Главный экран с нижней навигацией.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _titles = ['Проекты', 'Все задачи', 'Люди', 'Статистика'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          const _CurrentUserButton(),
          PopupMenuButton<String>(
            onSelected: (v) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => v == 'trash'
                    ? const TrashScreen()
                    : const PerformanceScreen(),
              ),
            ),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'trash',
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Корзина'),
                ),
              ),
              PopupMenuItem(
                value: 'performance',
                child: ListTile(
                  leading: Icon(Icons.speed),
                  title: Text('Производительность'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          ProjectsScreen(),
          _AllTasksTab(),
          UsersScreen(),
          DashboardScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Проекты',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: 'Задачи',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: 'Люди',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Статистика',
          ),
        ],
      ),
    );
  }
}

class _AllTasksTab extends StatelessWidget {
  const _AllTasksTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const TaskListPanel(filter: TaskFilter()),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-task',
        icon: const Icon(Icons.add_task),
        label: const Text('Задача'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TaskFormScreen.create()),
        ),
      ),
    );
  }
}

/// Аватар текущего пользователя: от его имени пишутся история и комментарии.
class _CurrentUserButton extends StatelessWidget {
  const _CurrentUserButton();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CurrentUserCubit>().state;
    final user = state.user;
    return IconButton(
      tooltip: user == null ? 'Нет пользователей' : 'Вы: ${user.name}',
      icon: user == null
          ? const Icon(Icons.person_off_outlined)
          : UserAvatar(user.name, radius: 15),
      onPressed: () async {
        if (state.users.isEmpty) {
          showResult(
            context,
            'Сначала создайте пользователя на вкладке «Люди»',
          );
          return;
        }
        final cubit = context.read<CurrentUserCubit>();
        final picked = await pickUser(
          context,
          state.users,
          title: 'Работать от имени',
        );
        if (picked != null) cubit.select(picked);
      },
    );
  }
}
