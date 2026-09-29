import '../../domain/entities/courier_job.dart';

class CourierJobModel extends CourierJob {
  const CourierJobModel({
    required super.id,
    required super.trackingNumber,
    required super.status,
    required super.senderName,
    required super.senderPhone,
    super.senderAddress,
    super.senderLat,
    super.senderLng,
    super.receiverName,
    super.receiverPhone,
    super.receiverAddress,
    super.receiverLat,
    super.receiverLng,
    super.distanceKm,
    required super.totalWeightKg,
    required super.isFragile,
    required super.isRefrigerated,
    required super.courierEarning,
    required super.paymentParty,
    required super.codAmount,
    required super.items,
    super.assignedAt,
    super.pickedUpAt,
    super.deliveredAt,
    super.estimatedArrival,
  });

  factory CourierJobModel.fromJson(Map<String, dynamic> json) {
    final itemsRaw = (json['items'] as List?) ?? [];
    final items = itemsRaw.map((e) {
      final m = e as Map<String, dynamic>;
      return CourierJobItem(
        id: m['id'] as String,
        type: m['type'] as String? ?? 'OTHER',
        description: m['description'] as String?,
        quantity: m['quantity'] as int? ?? 1,
        weightKg: (m['weightKg'] as num?)?.toDouble() ?? 0,
      );
    }).toList();

    return CourierJobModel(
      id: json['id'] as String,
      trackingNumber: json['trackingNumber'] as String,
      status: json['status'] as String,
      senderName: json['senderName'] as String,
      senderPhone: json['senderPhone'] as String,
      senderAddress: json['senderAddress'] as String?,
      senderLat: (json['senderLat'] as num?)?.toDouble(),
      senderLng: (json['senderLng'] as num?)?.toDouble(),
      receiverName: json['receiverName'] as String?,
      receiverPhone: json['receiverPhone'] as String?,
      receiverAddress: json['receiverAddress'] as String?,
      receiverLat: (json['receiverLat'] as num?)?.toDouble(),
      receiverLng: (json['receiverLng'] as num?)?.toDouble(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      totalWeightKg: (json['totalWeightKg'] as num?)?.toDouble() ?? 0,
      isFragile: json['isFragile'] as bool? ?? false,
      isRefrigerated: json['isRefrigerated'] as bool? ?? false,
      courierEarning: (json['courierEarning'] as num?)?.toDouble() ?? 0,
      paymentParty: json['paymentParty'] as String? ?? 'SENDER',
      codAmount: (json['codAmount'] as num?)?.toDouble() ?? 0,
      items: items,
      assignedAt: json['assignedAt'] != null
          ? DateTime.tryParse(json['assignedAt'])
          : null,
      pickedUpAt: json['pickedUpAt'] != null
          ? DateTime.tryParse(json['pickedUpAt'])
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'])
          : null,
      estimatedArrival: json['estimatedArrival'] != null
          ? DateTime.tryParse(json['estimatedArrival'])
          : null,
    );
  }
}
