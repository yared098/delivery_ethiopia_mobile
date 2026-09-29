import '../../domain/entities/courier_earning.dart';

class CourierEarningModel extends CourierEarning {
  const CourierEarningModel({
    required super.id,
    super.orderId,
    required super.amount,
    required super.currency,
    required super.type,
    required super.status,
    super.description,
    super.releasedAt,
    required super.createdAt,
    super.trackingNumber,
  });

  factory CourierEarningModel.fromJson(Map<String, dynamic> json) {
    final order = json['order'] as Map<String, dynamic>?;
    return CourierEarningModel(
      id: json['id'] as String,
      orderId: json['orderId'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'ETB',
      type: json['type'] as String? ?? 'DELIVERY',
      status: json['status'] as String? ?? 'PENDING',
      description: json['description'] as String?,
      releasedAt: json['releasedAt'] != null
          ? DateTime.tryParse(json['releasedAt'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      trackingNumber: order?['trackingNumber'] as String?,
    );
  }
}
