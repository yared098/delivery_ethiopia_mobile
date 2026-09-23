import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/order.dart';

abstract class OrdersRepository {
  Future<Either<Failure, DeliveryOrder>> createOrder({
    required OrderParty sender,
    required OrderParty receiver,
    required List<OrderItem> items,
    required String paymentParty,
    double codAmount,
    bool sendReceiverLink,
  });

  Future<Either<Failure, List<DeliveryOrder>>> listOrders({
    String type,
    int page,
    int limit,
  });

  Future<Either<Failure, DeliveryOrder>> getOrder(String id);
}
