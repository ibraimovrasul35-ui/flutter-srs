import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/dio_client.dart';
import 'data/local/post_cache.dart';
import 'data/remote/post_api.dart';
import 'data/repositories/post_repository.dart';
import 'presentation/screens/posts_screen.dart';
import 'presentation/state/posts_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Remote data source -> Repository -> Presentation
  final repository = PostRepository(
    api: PostApi(DioClient.instance),
    cache: PostCache(prefs),
  );

  runApp(PostExplorerApp(repository: repository));
}

class PostExplorerApp extends StatelessWidget {
  final PostRepository repository;

  const PostExplorerApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: repository,
      child: BlocProvider(
        create: (_) => PostsCubit(repository)..init(),
        child: MaterialApp(
          title: 'Post Explorer',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          ),
          home: const PostsScreen(),
        ),
      ),
    );
  }
}
