import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:srs6_flutter/models/get_posts.dart';
import 'package:srs6_flutter/post/repository/post_repository.dart';

part 'post_event.dart';
part 'post_state.dart';

class PostBloc extends Bloc<PostEvent, PostState> {
  final _repository = PostRepository();

  PostBloc() : super(PostInitial()) {
    on<GetPostEvent>(_onGetPosts);
  }

  Future<void> _onGetPosts(GetPostEvent event, Emitter<PostState> emit) async {
    emit(LoadingPostState());
    try {
      final posts = await _repository.getPosts();
      emit(FetchedPostsState(posts));
    } catch (e) {
      emit(FailurePostState());
    }
  }
}
