import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

/// DTO пользователя (GET /users). Вложенные Address (с Geo) и Company
/// нужны только для разбора JSON: в сущность `Author` попадают
/// лишь те поля, которые показывает приложение.
@JsonSerializable(checked: true, explicitToJson: true)
class UserModel {
  @JsonKey(required: true)
  final int id;

  @JsonKey(required: true)
  final String name;

  final String? username;
  final String? email;
  final String? phone;
  final String? website;
  final AddressModel? address;
  final CompanyModel? company;

  const UserModel({
    required this.id,
    required this.name,
    this.username,
    this.email,
    this.phone,
    this.website,
    this.address,
    this.company,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}

@JsonSerializable(checked: true, explicitToJson: true)
class AddressModel {
  final String? street;
  final String? suite;
  final String? city;
  final String? zipcode;
  final GeoModel? geo;

  const AddressModel(
      {this.street, this.suite, this.city, this.zipcode, this.geo});

  factory AddressModel.fromJson(Map<String, dynamic> json) =>
      _$AddressModelFromJson(json);

  Map<String, dynamic> toJson() => _$AddressModelToJson(this);
}

@JsonSerializable(checked: true)
class GeoModel {
  final String? lat;
  final String? lng;

  const GeoModel({this.lat, this.lng});

  factory GeoModel.fromJson(Map<String, dynamic> json) =>
      _$GeoModelFromJson(json);

  Map<String, dynamic> toJson() => _$GeoModelToJson(this);
}

@JsonSerializable(checked: true)
class CompanyModel {
  final String? name;
  final String? catchPhrase;
  final String? bs;

  const CompanyModel({this.name, this.catchPhrase, this.bs});

  factory CompanyModel.fromJson(Map<String, dynamic> json) =>
      _$CompanyModelFromJson(json);

  Map<String, dynamic> toJson() => _$CompanyModelToJson(this);
}
