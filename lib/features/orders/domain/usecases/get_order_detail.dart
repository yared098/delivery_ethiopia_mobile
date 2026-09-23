import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/order.dart';
import '../repositories/orders_repository.dart';

class GetOrderDetail {
  GetOrderDetail(this._repo);
  final OrdersRepository _repo;
  Future<Either<Failure, DeliveryOrder>> call(String id) => _repo.getOrder(id);
}
