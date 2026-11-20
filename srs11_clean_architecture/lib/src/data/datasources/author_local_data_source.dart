import '../../../constants/storage_keys.dart';
import '../../../models/user_model.dart';
import 'json_storage.dart';

/// Сохранённый список авторов: нужен, чтобы имена авторов были видны
/// и без интернета.
abstract interface class AuthorLocalDataSource {
  List<UserModel>? readUsers();

  Future<void> saveUsers(List<UserModel> users);
}

class AuthorLocalDataSourceImpl implements AuthorLocalDataSource {
  final JsonStorage _storage;

  const AuthorLocalDataSourceImpl(this._storage);

  @override
  List<UserModel>? readUsers() =>
      _storage.readList(StorageKeys.users, UserModel.fromJson)?.data;

  @override
  Future<void> saveUsers(List<UserModel> users) => _storage.writeList(
      StorageKeys.users, users.map((u) => u.toJson()).toList());
}
