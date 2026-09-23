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

  bool get isTerminal =>
      this == delivered || this == cancelled || this == failed || this == returned;
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

class OrderCourier extends Equatable {
  const OrderCourier({
    required this.id,
    required this.name,
    required this.phone,
    this.vehicleType,
    this.vehiclePlate,
    this.rating,
    this.currentLat,
    this.currentLng,
  });
  final String id;
  final String name;
  final String phone;
  final String? vehicleType;
  final String? vehiclePlate;
  final double? rating;
  final double? currentLat;
  final double? currentLng;

  @override
  List<Object?> get props => [id, name, phone, vehicleType, vehiclePlate, rating];
}

class OrderEventItem extends Equatable {
  const OrderEventItem({
    required this.status,
    this.note,
    this.location,
    required this.createdAt,
    this.isPublic = true,
  });
  final String status;
  final String? note;
  final String? location;
  final DateTime createdAt;
  final bool isPublic;

  @override
  List<Object?> get props => [status, note, createdAt];
}

class DeliveryOrder extends Equatable {
  const DeliveryOrder({
    required this.id,
    this.trackingNumber,
    this.trackingUrl,
    this.trackingToken,
    required this.status,
    required this.sender,
    required this.receiver,
    required this.items,
    required this.paymentParty,
    this.paymentStatus,
    this.paymentMethod,
    this.codAmount = 0,
    this.deliveryFee = 0,
    this.distanceKm,
    this.totalWeightKg = 0,
    this.isFragile = false,
    this.isRefrigerated = false,
    this.packageDescription,
    this.courier,
    this.events = const [],
    this.estimatedArrival,
    this.createdAt,
    this.paidAt,
    this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.cancelledAt,
  });

  final String id;
  final String? trackingNumber;
  final String? trackingUrl;
  final String? trackingToken;
  final OrderStatus status;
  final OrderParty sender;
  final OrderParty receiver;
  final List<OrderItem> items;
  final String paymentParty; // SENDER | RECEIVER | SPLIT
  final String? paymentStatus;
  final String? paymentMethod;
  final double codAmount;
  final double deliveryFee;
  final double? distanceKm;
  final double totalWeightKg;
  final bool isFragile;
  final bool isRefrigerated;
  final String? packageDescription;
  final OrderCourier? courier;
  final List<OrderEventItem> events;
  final DateTime? estimatedArrival;
  final DateTime? createdAt;
  final DateTime? paidAt;
  final DateTime? assignedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;

  @override
  List<Object?> get props => [id, status, trackingNumber, createdAt, updatedAtKey];
  // any change to status/times rebuilds
  String get updatedAtKey =>
      '${status.name}:${deliveredAt?.toIso8601String() ?? ''}:${assignedAt?.toIso8601String() ?? ''}';
}
