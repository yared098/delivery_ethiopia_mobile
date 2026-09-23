import '../../domain/entities/order.dart';

class OrderModel extends DeliveryOrder {
  const OrderModel({
    required super.id,
    super.trackingNumber,
    super.trackingUrl,
    super.trackingToken,
    required super.status,
    required super.sender,
    required super.receiver,
    required super.items,
    required super.paymentParty,
    super.paymentStatus,
    super.paymentMethod,
    super.codAmount,
    super.deliveryFee,
    super.distanceKm,
    super.totalWeightKg,
    super.isFragile,
    super.isRefrigerated,
    super.packageDescription,
    super.courier,
    super.events,
    super.estimatedArrival,
    super.createdAt,
    super.paidAt,
    super.assignedAt,
    super.pickedUpAt,
    super.deliveredAt,
    super.cancelledAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> j) => OrderModel(
        id: (j['id'] ?? '') as String,
        trackingNumber: j['trackingNumber'] as String?,
        trackingUrl: j['trackingUrl'] as String?,
        trackingToken: j['trackingToken'] as String?,
        status: OrderStatus.fromString((j['status'] ?? 'DRAFT') as String),

        sender: _partyFromJson(
          nested: j['sender'],
          nameKey: j['senderName'],
          phoneKey: j['senderPhone'],
          addressKey: j['senderAddress'],
          latKey: j['senderLat'],
          lngKey: j['senderLng'],
        ),
        receiver: _partyFromJson(
          nested: j['receiver'],
          nameKey: j['receiverName'],
          phoneKey: j['receiverPhone'],
          addressKey: j['receiverAddress'],
          latKey: j['receiverLat'],
          lngKey: j['receiverLng'],
        ),

        items: ((j['items'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => _item(e.cast<String, dynamic>()))
            .toList(),

        paymentParty: (j['paymentParty'] ?? 'SENDER') as String,
        paymentStatus: j['paymentStatus'] as String?,
        paymentMethod: j['paymentMethod'] as String?,
        codAmount: (j['codAmount'] as num?)?.toDouble() ?? 0,
        deliveryFee: (j['deliveryFee'] as num?)?.toDouble() ?? 0,
        distanceKm: (j['distanceKm'] as num?)?.toDouble(),
        totalWeightKg: (j['totalWeightKg'] as num?)?.toDouble() ?? 0,
        isFragile: j['isFragile'] as bool? ?? false,
        isRefrigerated: j['isRefrigerated'] as bool? ?? false,
        packageDescription: j['packageDescription'] as String?,

        courier: j['courier'] is Map
            ? _courier((j['courier'] as Map).cast<String, dynamic>())
            : null,

        events: ((j['events'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => _event(e.cast<String, dynamic>()))
            .toList(),

        estimatedArrival: _dt(j['estimatedArrival']),
        createdAt: _dt(j['createdAt']),
        paidAt: _dt(j['paidAt']),
        assignedAt: _dt(j['assignedAt']),
        pickedUpAt: _dt(j['pickedUpAt']),
        deliveredAt: _dt(j['deliveredAt']),
        cancelledAt: _dt(j['cancelledAt']),
      );

  static DateTime? _dt(dynamic v) =>
      v is String ? DateTime.tryParse(v) : null;

  static OrderParty _partyFromJson({
    required dynamic nested,
    dynamic nameKey,
    dynamic phoneKey,
    dynamic addressKey,
    dynamic latKey,
    dynamic lngKey,
  }) {
    if (nested is Map) {
      final m = nested.cast<String, dynamic>();
      return OrderParty(
        name: m['name'] as String?,
        phone: (m['phone'] ?? '') as String,
        address: m['address'] as String?,
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
      );
    }
    return OrderParty(
      name: nameKey as String?,
      phone: (phoneKey ?? '') as String,
      address: addressKey as String?,
      lat: (latKey as num?)?.toDouble(),
      lng: (lngKey as num?)?.toDouble(),
    );
  }

  static OrderItem _item(Map<String, dynamic> m) => OrderItem(
        type: (m['type'] ?? 'PARCEL') as String,
        description: (m['description'] ?? '') as String,
        quantity: ((m['quantity'] ?? 1) as num).toInt(),
        weightKg: ((m['weightKg'] ?? 0) as num).toDouble(),
        isFragile: m['isFragile'] as bool? ?? false,
        isRefrigerated: m['isRefrigerated'] as bool? ?? false,
        declaredValue: (m['declaredValue'] as num?)?.toDouble(),
      );

  static OrderCourier _courier(Map<String, dynamic> m) => OrderCourier(
        id: (m['id'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        phone: (m['phone'] ?? '') as String,
        vehicleType: m['vehicleType'] as String?,
        vehiclePlate: m['vehiclePlate'] as String?,
        rating: (m['rating'] as num?)?.toDouble(),
        currentLat: (m['currentLat'] as num?)?.toDouble(),
        currentLng: (m['currentLng'] as num?)?.toDouble(),
      );

  static OrderEventItem _event(Map<String, dynamic> m) => OrderEventItem(
        status: (m['status'] ?? '') as String,
        note: m['note'] as String?,
        location: m['location'] as String?,
        createdAt: DateTime.tryParse((m['createdAt'] ?? '') as String) ??
            DateTime.now(),
        isPublic: m['isPublic'] as bool? ?? true,
      );
}
