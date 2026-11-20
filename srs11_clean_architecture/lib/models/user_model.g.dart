// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => $checkedCreate(
  'UserModel',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['id', 'name']);
    final val = UserModel(
      id: $checkedConvert('id', (v) => (v as num).toInt()),
      name: $checkedConvert('name', (v) => v as String),
      username: $checkedConvert('username', (v) => v as String?),
      email: $checkedConvert('email', (v) => v as String?),
      phone: $checkedConvert('phone', (v) => v as String?),
      website: $checkedConvert('website', (v) => v as String?),
      address: $checkedConvert(
        'address',
        (v) =>
            v == null ? null : AddressModel.fromJson(v as Map<String, dynamic>),
      ),
      company: $checkedConvert(
        'company',
        (v) =>
            v == null ? null : CompanyModel.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'username': instance.username,
  'email': instance.email,
  'phone': instance.phone,
  'website': instance.website,
  'address': instance.address?.toJson(),
  'company': instance.company?.toJson(),
};

AddressModel _$AddressModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AddressModel', json, ($checkedConvert) {
      final val = AddressModel(
        street: $checkedConvert('street', (v) => v as String?),
        suite: $checkedConvert('suite', (v) => v as String?),
        city: $checkedConvert('city', (v) => v as String?),
        zipcode: $checkedConvert('zipcode', (v) => v as String?),
        geo: $checkedConvert(
          'geo',
          (v) =>
              v == null ? null : GeoModel.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AddressModelToJson(AddressModel instance) =>
    <String, dynamic>{
      'street': instance.street,
      'suite': instance.suite,
      'city': instance.city,
      'zipcode': instance.zipcode,
      'geo': instance.geo?.toJson(),
    };

GeoModel _$GeoModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GeoModel', json, ($checkedConvert) {
      final val = GeoModel(
        lat: $checkedConvert('lat', (v) => v as String?),
        lng: $checkedConvert('lng', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$GeoModelToJson(GeoModel instance) => <String, dynamic>{
  'lat': instance.lat,
  'lng': instance.lng,
};

CompanyModel _$CompanyModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CompanyModel', json, ($checkedConvert) {
      final val = CompanyModel(
        name: $checkedConvert('name', (v) => v as String?),
        catchPhrase: $checkedConvert('catchPhrase', (v) => v as String?),
        bs: $checkedConvert('bs', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$CompanyModelToJson(CompanyModel instance) =>
    <String, dynamic>{
      'name': instance.name,
      'catchPhrase': instance.catchPhrase,
      'bs': instance.bs,
    };
