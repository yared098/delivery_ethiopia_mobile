import '../../domain/entities/courier.dart';

class CourierModel extends Courier {
  const CourierModel({
    required super.id,
    required super.phone,
    required super.name,
    super.email,
    required super.regionId,
    required super.branchId,
    required super.vehicleType,
    super.vehiclePlate,
    super.vehicleModel,
    super.vehicleColor,
    required super.status,
    required super.isActive,
    required super.phoneVerified,
    required super.rating,
    required super.totalDeliveries,
    required super.totalFailed,
    required super.isOnline,
    super.currentLat,
    super.currentLng,
    super.lastSeenAt,
    required super.regionName,
    required super.branchName,
  });

  factory CourierModel.fromJson(Map<String, dynamic> json) {
    final region = json['region'] as Map<String, dynamic>?;
    final branch = json['branch'] as Map<String, dynamic>?;

    return CourierModel(
      id: json['id'] as String,
      phone: json['phone'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      regionId: json['regionId'] as String,
      branchId: json['branchId'] as String,
      vehicleType: json['vehicleType'] as String,
      vehiclePlate: json['vehiclePlate'] as String?,
      vehicleModel: json['vehicleModel'] as String?,
      vehicleColor: json['vehicleColor'] as String?,
      status: json['status'] as String,
      isActive: json['isActive'] as bool? ?? true,
      phoneVerified: json['phoneVerified'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      totalDeliveries: json['totalDeliveries'] as int? ?? 0,
      totalFailed: json['totalFailed'] as int? ?? 0,
      isOnline: json['isOnline'] as bool? ?? false,
      currentLat: (json['currentLat'] as num?)?.toDouble(),
      currentLng: (json['currentLng'] as num?)?.toDouble(),
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.tryParse(json['lastSeenAt'])
          : null,
      regionName: region?['name'] as String? ?? '',
      branchName: branch?['name'] as String? ?? '',
    );
  }
}
