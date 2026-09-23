import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/order.dart';
import '../models/order_model.dart';

class OrdersRemoteDataSource {
  OrdersRemoteDataSource(this._dio);
  final Dio _dio;

  Future<OrderModel> create({
    required OrderParty sender,
    required OrderParty receiver,
    required List<OrderItem> items,
    required String paymentParty,
    double codAmount = 0,
    bool sendReceiverLink = false,
  }) async {
    final body = {
      'sender': _partyToJson(sender),
      'receiver': _partyToJson(receiver),
      'items': items.map(_itemToJson).toList(),
      'paymentParty': paymentParty,
      'codAmount': codAmount,
      'sendReceiverLink': sendReceiverLink,
    };
    final res = await _dio.post(ApiConstants.orders, data: body);

    final raw = res.data;
    // Backend wraps: { order: {...}, receiverLink, courierAssigned }
    if (raw is Map && raw['order'] is Map) {
      return OrderModel.fromJson(
        (raw['order'] as Map).cast<String, dynamic>(),
      );
    }
    // Fallback — some deployments may return the order directly
    return OrderModel.fromJson((raw as Map).cast<String, dynamic>());
  }

  Future<List<OrderModel>> list({
    String type = 'all',
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get(
      ApiConstants.orders,
      queryParameters: {'type': type, 'page': page, 'limit': limit},
    );
    final raw = res.data;
    final List<dynamic> data = raw is Map && raw['data'] is List
        ? raw['data'] as List<dynamic>
        : (raw as List<dynamic>);
    return data
        .whereType<Map>()
        .map((e) => OrderModel.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<OrderModel> detail(String id) async {
    final res = await _dio.get(ApiConstants.orderDetail(id));
    final raw = res.data;
    // Detail may also be wrapped: { order: {...} }
    if (raw is Map && raw['order'] is Map) {
      return OrderModel.fromJson(
        (raw['order'] as Map).cast<String, dynamic>(),
      );
    }
    return OrderModel.fromJson((raw as Map).cast<String, dynamic>());
  }

  Map<String, dynamic> _partyToJson(OrderParty p) {
    final m = <String, dynamic>{
      'name': p.name,
      'phone': p.phone,
      'address': p.address,
      'lat': p.lat,
      'lng': p.lng,
    };
    m.removeWhere((_, v) => v == null);
    return m;
  }

  Map<String, dynamic> _itemToJson(OrderItem i) {
    final m = <String, dynamic>{
      'type': i.type,
      'description': i.description,
      'quantity': i.quantity,
      'weightKg': i.weightKg,
      'isFragile': i.isFragile,
      'isRefrigerated': i.isRefrigerated,
      'declaredValue': i.declaredValue,
    };
    m.removeWhere((_, v) => v == null);
    return m;
  }
}
