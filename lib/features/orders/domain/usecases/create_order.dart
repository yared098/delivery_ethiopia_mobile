import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/order.dart';
import '../repositories/orders_repository.dart';

class CreateOrder {
  CreateOrder(this._repo);
  final OrdersRepository _repo;

  Future<Either<Failure, DeliveryOrder>> call({
    required OrderParty sender,
    required OrderParty receiver,
    required List<OrderItem> items,
    required String paymentParty,
    double codAmount = 0,
    bool sendReceiverLink = false,
  }) => _repo.createOrder(
    sender: sender,
    receiver: receiver,
    items: items,
    paymentParty: paymentParty,
    codAmount: codAmount,
    sendReceiverLink: sendReceiverLink,
  );
}
