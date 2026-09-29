class CourierJobItem {
  final String id;
  final String type;
  final String? description;
  final int quantity;
  final double weightKg;

  const CourierJobItem({
    required this.id,
    required this.type,
    this.description,
    required this.quantity,
    required this.weightKg,
  });
}

class CourierJob {
  final String id;
  final String trackingNumber;
  final String status;
  final String senderName;
  final String senderPhone;
  final String? senderAddress;
  final double? senderLat;
  final double? senderLng;
  final String? receiverName;
  final String? receiverPhone;
  final String? receiverAddress;
  final double? receiverLat;
  final double? receiverLng;
  final double? distanceKm;
  final double totalWeightKg;
  final bool isFragile;
  final bool isRefrigerated;
  final double courierEarning;
  final String paymentParty;
  final double codAmount;
  final List<CourierJobItem> items;
  final DateTime? assignedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? estimatedArrival;

  const CourierJob({
    required this.id,
    required this.trackingNumber,
    required this.status,
    required this.senderName,
    required this.senderPhone,
    this.senderAddress,
    this.senderLat,
    this.senderLng,
    this.receiverName,
    this.receiverPhone,
    this.receiverAddress,
    this.receiverLat,
    this.receiverLng,
    this.distanceKm,
    required this.totalWeightKg,
    required this.isFragile,
    required this.isRefrigerated,
    required this.courierEarning,
    required this.paymentParty,
    required this.codAmount,
    required this.items,
    this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.estimatedArrival,
  });

  bool get isActive => const [
        'ASSIGNED',
        'PICKED_UP',
        'IN_TRANSIT',
        'OUT_FOR_DELIVERY',
      ].contains(status);
}
