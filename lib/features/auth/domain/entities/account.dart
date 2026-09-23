import 'package:equatable/equatable.dart';

class Account extends Equatable {
  const Account({
    required this.id,
    required this.phone,
    this.name,
    this.email,
    this.defaultAddress,
    this.defaultLat,
    this.defaultLng,
    this.phoneVerified = false,
    this.createdAt,
  });

  final String id;
  final String phone;
  final String? name;
  final String? email;
  final String? defaultAddress;
  final double? defaultLat;
  final double? defaultLng;
  final bool phoneVerified;
  final DateTime? createdAt;

  bool get isProfileComplete => (name?.isNotEmpty ?? false);

  Account copyWith({
    String? name,
    String? email,
    String? defaultAddress,
    double? defaultLat,
    double? defaultLng,
  }) => Account(
    id: id,
    phone: phone,
    name: name ?? this.name,
    email: email ?? this.email,
    defaultAddress: defaultAddress ?? this.defaultAddress,
    defaultLat: defaultLat ?? this.defaultLat,
    defaultLng: defaultLng ?? this.defaultLng,
    phoneVerified: phoneVerified,
    createdAt: createdAt,
  );

  @override
  List<Object?> get props =>
      [id, phone, name, email, defaultAddress, defaultLat, defaultLng, phoneVerified];
}
