import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'src/presentation/bloc/favorites/favorites_cubit.dart';
import 'src/presentation/bloc/posts/posts_cubit.dart';
import 'src/presentation/pages/posts_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // DataSource → Repository → UseCase → Bloc (core/di/injection.dart)
  await initDependencies();
  runApp(const PostExplorerApp());
}

class PostExplorerApp extends StatelessWidget {
  const PostExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<PostsCubit>()..init()),
        BlocProvider(create: (_) => sl<FavoritesCubit>()..load()),
      ],
      child: MaterialApp(
        title: 'Post Explorer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        ),
        home: const PostsPage(),
      ),
    );
  }
}
