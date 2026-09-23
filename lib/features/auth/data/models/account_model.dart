import '../../domain/entities/account.dart';

class AccountModel extends Account {
  const AccountModel({
    required super.id,
    required super.phone,
    super.name,
    super.email,
    super.defaultAddress,
    super.defaultLat,
    super.defaultLng,
    super.phoneVerified,
    super.createdAt,
  });

  factory AccountModel.fromJson(Map<String, dynamic> j) => AccountModel(
    id: j['id'] as String,
    phone: j['phone'] as String,
    name: j['name'] as String?,
    email: j['email'] as String?,
    defaultAddress: j['defaultAddress'] as String?,
    defaultLat: (j['defaultLat'] as num?)?.toDouble(),
    defaultLng: (j['defaultLng'] as num?)?.toDouble(),
    phoneVerified: j['phoneVerified'] as bool? ?? false,
    createdAt: j['createdAt'] != null
        ? DateTime.tryParse(j['createdAt'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'name': name,
    'email': email,
    'defaultAddress': defaultAddress,
    'defaultLat': defaultLat,
    'defaultLng': defaultLng,
    'phoneVerified': phoneVerified,
    'createdAt': createdAt?.toIso8601String(),
  };
}
