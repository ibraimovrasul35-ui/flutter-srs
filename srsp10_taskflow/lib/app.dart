import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/database/app_database.dart';
import 'data/repositories/attachment_repository.dart';
import 'data/repositories/comment_repository.dart';
import 'data/repositories/performance_repository.dart';
import 'data/repositories/project_repository.dart';
import 'data/repositories/stats_repository.dart';
import 'data/repositories/task_repository.dart';
import 'data/repositories/user_repository.dart';
import 'presentation/screens/home_screen.dart';
import 'state/current_user_cubit.dart';
import 'state/entity_cubits.dart';

/// Корень приложения: репозитории и общие Cubit'ы доступны всем экранам.
class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key, required this.database});

  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: database),
        RepositoryProvider(create: (_) => UserRepository(database)),
        RepositoryProvider(create: (_) => ProjectRepository(database)),
        RepositoryProvider(create: (_) => TaskRepository(database)),
        RepositoryProvider(create: (_) => CommentRepository(database)),
        RepositoryProvider(create: (_) => AttachmentRepository(database)),
        RepositoryProvider(create: (_) => StatsRepository(database)),
        RepositoryProvider(create: (_) => PerformanceRepository(database)),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (c) => CurrentUserCubit(c.read<UserRepository>()),
          ),
          BlocProvider(create: (c) => UsersCubit(c.read<UserRepository>())),
          BlocProvider(
            create: (c) => ProjectsCubit(c.read<ProjectRepository>()),
          ),
          BlocProvider(
            create: (c) => DashboardCubit(c.read<StatsRepository>()),
          ),
        ],
        child: MaterialApp(
          title: 'TaskFlow',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
          locale: const Locale('ru'),
          supportedLocales: const [Locale('ru'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
