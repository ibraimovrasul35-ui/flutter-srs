import 'dart:developer' as developer;

import 'package:fpdart/fpdart.dart';

import '../../../models/user_model.dart';
import '../../domain/entities/author.dart';
import '../../domain/failures/failures.dart';
import '../../domain/repositories/author_repository.dart';
import '../datasources/author_local_data_source.dart';
import '../datasources/author_remote_data_source.dart';
import '../mapper/failure_mapper.dart';
import '../mapper/post_mapper.dart';

/// Авторы нужны сразу нескольким экранам (список, фильтр, форма,
/// детали). Чтобы не делать лишних запросов:
/// * список загружается с сервера один раз и хранится в памяти;
/// * одновременные вызовы ждут один и тот же запрос;
/// * автор для экрана деталей берётся из уже загруженного списка.
class AuthorRepositoryImpl implements AuthorRepository {
  final AuthorRemoteDataSource _remote;
  final AuthorLocalDataSource _local;

  AuthorRepositoryImpl({
    required this._remote,
    required this._local,
  });

  List<Author>? _memory;
  Future<List<UserModel>>? _inFlight;

  @override
  Future<Either<Failure, List<Author>>> getAuthors() async {
    final memory = _memory;
    if (memory != null) return Right(memory);

    final result = await guard(() async {
      final request = _inFlight ??= _remote.getUsers();
      try {
        final models = await request;
        try {
          await _local.saveUsers(models);
        } catch (e) {
          developer.log('Cache write failed: $e', name: 'PostExplorer.cache');
        }
        return _memory = models.map((m) => m.toEntity()).toList();
      } finally {
        if (identical(_inFlight, request)) _inFlight = null;
      }
    });

    // Offline: если сервер недоступен, отдаём сохранённую копию.
    return result.fold((failure) {
      final saved = _local.readUsers();
      if (saved == null) return Left(failure);
      return Right(saved.map((m) => m.toEntity()).toList());
    }, Right.new);
  }

  @override
  Future<Either<Failure, Author>> getAuthor(int id) async {
    final known = _find(_memory, id) ??
        _find(_local.readUsers()?.map((m) => m.toEntity()).toList(), id);
    if (known != null) return Right(known);
    return guard(() async => (await _remote.getUser(id)).toEntity());
  }

  static Author? _find(List<Author>? authors, int id) {
    if (authors == null) return null;
    for (final a in authors) {
      if (a.id == id) return a;
    }
    return null;
  }
}
