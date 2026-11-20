import 'package:equatable/equatable.dart';

/// Автор поста. В отличие от UserModel здесь только те поля,
/// которые нужны приложению (вложенные Address/Geo не нужны).
class Author extends Equatable {
  final int id;
  final String name;
  final String? email;
  final String? companyName;
  final String? city;

  const Author({
    required this.id,
    required this.name,
    this.email,
    this.companyName,
    this.city,
  });

  @override
  List<Object?> get props => [id, name, email, companyName, city];
}
