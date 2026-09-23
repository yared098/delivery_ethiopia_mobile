import '../../domain/entities/order.dart';

class OrderModel extends DeliveryOrder {
  const OrderModel({
    required super.id,
    super.trackingNumber,
    required super.status,
    required super.sender,
    required super.receiver,
    required super.items,
    required super.paymentParty,
    super.paymentStatus,
    super.codAmount,
    super.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> j) => OrderModel(
    id: (j['id'] ?? '') as String,
    trackingNumber: j['trackingNumber'] as String?,
    status: OrderStatus.fromString((j['status'] ?? 'DRAFT') as String),

    // Sender — supports both shapes:
    //   { "sender": { "name": ..., "phone": ... } }  ← admin docs
    //   { "senderName": ..., "senderPhone": ... }    ← your create response
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
    codAmount: (j['codAmount'] as num?)?.toDouble() ?? 0,
    createdAt: j['createdAt'] != null
        ? DateTime.tryParse(j['createdAt'] as String)
        : null,
  );

  /// Handles both nested and flat party shapes safely.
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
}
