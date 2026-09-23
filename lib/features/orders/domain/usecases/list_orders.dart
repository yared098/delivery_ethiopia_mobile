import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/order.dart';
import '../repositories/orders_repository.dart';

class ListOrders {
  ListOrders(this._repo);
  final OrdersRepository _repo;

  Future<Either<Failure, List<DeliveryOrder>>> call({
    String type = 'all',
    int page = 1,
    int limit = 20,
  }) => _repo.listOrders(type: type, page: page, limit: limit);
}
