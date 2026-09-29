class Courier {
  final String id;
  final String phone;
  final String name;
  final String? email;
  final String regionId;
  final String branchId;
  final String vehicleType;
  final String? vehiclePlate;
  final String? vehicleModel;
  final String? vehicleColor;
  final String status;
  final bool isActive;
  final bool phoneVerified;
  final double rating;
  final int totalDeliveries;
  final int totalFailed;
  final bool isOnline;
  final double? currentLat;
  final double? currentLng;
  final DateTime? lastSeenAt;
  final String regionName;
  final String branchName;

  const Courier({
    required this.id,
    required this.phone,
    required this.name,
    this.email,
    required this.regionId,
    required this.branchId,
    required this.vehicleType,
    this.vehiclePlate,
    this.vehicleModel,
    this.vehicleColor,
    required this.status,
    required this.isActive,
    required this.phoneVerified,
    required this.rating,
    required this.totalDeliveries,
    required this.totalFailed,
    required this.isOnline,
    this.currentLat,
    this.currentLng,
    this.lastSeenAt,
    required this.regionName,
    required this.branchName,
  });

  Courier copyWith({bool? isOnline, double? currentLat, double? currentLng}) {
    return Courier(
      id: id,
      phone: phone,
      name: name,
      email: email,
      regionId: regionId,
      branchId: branchId,
      vehicleType: vehicleType,
      vehiclePlate: vehiclePlate,
      vehicleModel: vehicleModel,
      vehicleColor: vehicleColor,
      status: status,
      isActive: isActive,
      phoneVerified: phoneVerified,
      rating: rating,
      totalDeliveries: totalDeliveries,
      totalFailed: totalFailed,
      isOnline: isOnline ?? this.isOnline,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      lastSeenAt: lastSeenAt,
      regionName: regionName,
      branchName: branchName,
    );
  }
}
