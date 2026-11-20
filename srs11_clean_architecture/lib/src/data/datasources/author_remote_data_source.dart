import '../../../core/rest_client/rest_client.dart';
import '../../../models/user_model.dart';
import '../exceptions/exception_mapper.dart';

abstract interface class AuthorRemoteDataSource {
  Future<List<UserModel>> getUsers();

  Future<UserModel> getUser(int id);
}

class AuthorRemoteDataSourceImpl implements AuthorRemoteDataSource {
  final RestClient _client;

  const AuthorRemoteDataSourceImpl(this._client);

  @override
  Future<List<UserModel>> getUsers() => _call(_client.getUsers);

  @override
  Future<UserModel> getUser(int id) => _call(() => _client.getUser(id));

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } catch (e) {
      throw ExceptionMapper.map(e);
    }
  }
}
