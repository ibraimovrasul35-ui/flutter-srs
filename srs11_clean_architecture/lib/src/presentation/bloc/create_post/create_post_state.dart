part of 'create_post_cubit.dart';

enum AuthorsStatus { loading, success, empty, failure }

enum SubmitStatus { idle, submitting, success, failure }

final class CreatePostState extends Equatable {
  final AuthorsStatus authorsStatus;
  final List<Author> authors;
  final Failure? authorsFailure;
  final SubmitStatus submitStatus;
  final Post? createdPost; // пост, который вернул сервер
  final Failure? submitFailure;

  const CreatePostState({
    this.authorsStatus = AuthorsStatus.loading,
    this.authors = const [],
    this.authorsFailure,
    this.submitStatus = SubmitStatus.idle,
    this.createdPost,
    this.submitFailure,
  });

  bool get isSubmitting => submitStatus == SubmitStatus.submitting;

  CreatePostState copyWith({
    AuthorsStatus? authorsStatus,
    List<Author>? authors,
    Failure? authorsFailure,
    SubmitStatus? submitStatus,
    Post? createdPost,
    Failure? submitFailure,
  }) {
    return CreatePostState(
      authorsStatus: authorsStatus ?? this.authorsStatus,
      authors: authors ?? this.authors,
      authorsFailure: authorsFailure ?? this.authorsFailure,
      submitStatus: submitStatus ?? this.submitStatus,
      createdPost: createdPost ?? this.createdPost,
      submitFailure: submitFailure ?? this.submitFailure,
    );
  }

  @override
  List<Object?> get props => [
        authorsStatus,
        authors,
        authorsFailure,
        submitStatus,
        createdPost,
        submitFailure,
      ];
}
