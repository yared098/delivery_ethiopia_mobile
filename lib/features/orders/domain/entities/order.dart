import 'package:equatable/equatable.dart';

enum OrderStatus {
  draft,
  awaitingReceiverLocation,
  pendingPayment,
  paid,
  assigned,
  pickedUp,
  inTransit,
  outForDelivery,
  delivered,
  failed,
  cancelled,
  returned;

  static OrderStatus fromString(String v) => switch (v) {
    'DRAFT' => draft,
    'AWAITING_RECEIVER_LOCATION' => awaitingReceiverLocation,
    'PENDING_PAYMENT' => pendingPayment,
    'PAID' => paid,
    'ASSIGNED' => assigned,
    'PICKED_UP' => pickedUp,
    'IN_TRANSIT' => inTransit,
    'OUT_FOR_DELIVERY' => outForDelivery,
    'DELIVERED' => delivered,
    'FAILED' => failed,
    'CANCELLED' => cancelled,
    'RETURNED' => returned,
    _ => draft,
  };

  String get label => switch (this) {
    draft => 'Draft',
    awaitingReceiverLocation => 'Waiting for receiver GPS',
    pendingPayment => 'Pending payment',
    paid => 'Paid',
    assigned => 'Courier assigned',
    pickedUp => 'Picked up',
    inTransit => 'In transit',
    outForDelivery => 'Out for delivery',
    delivered => 'Delivered',
    failed => 'Failed',
    cancelled => 'Cancelled',
    returned => 'Returned',
  };
}

class OrderParty extends Equatable {
  const OrderParty({
    this.name,
    required this.phone,
    this.address,
    this.lat,
    this.lng,
  });
  final String? name;
  final String phone;
  final String? address;
  final double? lat;
  final double? lng;

  @override
  List<Object?> get props => [name, phone, address, lat, lng];
}

class OrderItem extends Equatable {
  const OrderItem({
    required this.type,
    required this.description,
    required this.quantity,
    required this.weightKg,
    this.isFragile = false,
    this.isRefrigerated = false,
    this.declaredValue,
  });
  final String type;
  final String description;
  final int quantity;
  final double weightKg;
  final bool isFragile;
  final bool isRefrigerated;
  final double? declaredValue;

  @override
  List<Object?> get props => [
    type, description, quantity, weightKg, isFragile, isRefrigerated, declaredValue,
  ];
}

/// Renamed from `Order` to avoid a name collision with dartz's `Order`.
class DeliveryOrder extends Equatable {
  const DeliveryOrder({
    required this.id,
    this.trackingNumber,
    required this.status,
    required this.sender,
    required this.receiver,
    required this.items,
    required this.paymentParty,
    this.paymentStatus,
    this.codAmount = 0,
    this.createdAt,
  });
  final String id;
  final String? trackingNumber;
  final OrderStatus status;
  final OrderParty sender;
  final OrderParty receiver;
  final List<OrderItem> items;
  final String paymentParty;
  final String? paymentStatus;
  final double codAmount;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, status, trackingNumber, createdAt];
}
