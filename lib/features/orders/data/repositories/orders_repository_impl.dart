import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/error_helper.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_remote_datasource.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  OrdersRepositoryImpl(this._remote);
  final OrdersRemoteDataSource _remote;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } on DioException catch (e) {
      return Left(Failure(friendlyError(e), statusCode: e.response?.statusCode));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DeliveryOrder>> createOrder({
    required OrderParty sender,
    required OrderParty receiver,
    required List<OrderItem> items,
    required String paymentParty,
    double codAmount = 0,
    bool sendReceiverLink = false,
  }) => _guard(() => _remote.create(
    sender: sender,
    receiver: receiver,
    items: items,
    paymentParty: paymentParty,
    codAmount: codAmount,
    sendReceiverLink: sendReceiverLink,
  ));

  @override
  Future<Either<Failure, List<DeliveryOrder>>> listOrders({
    String type = 'all',
    int page = 1,
    int limit = 20,
  }) => _guard(() => _remote.list(type: type, page: page, limit: limit));

  @override
  Future<Either<Failure, DeliveryOrder>> getOrder(String id) =>
      _guard(() => _remote.detail(id));
}
