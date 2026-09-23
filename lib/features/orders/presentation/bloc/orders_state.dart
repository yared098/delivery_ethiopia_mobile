import 'package:equatable/equatable.dart';
import '../../domain/entities/order.dart';

abstract class OrdersState extends Equatable {
  const OrdersState();
  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {}
class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  const OrdersLoaded(this.orders);
  final List<DeliveryOrder> orders;
  @override
  List<Object?> get props => [orders];
}

class OrderDetailLoaded extends OrdersState {
  const OrderDetailLoaded(this.order);
  final DeliveryOrder order;
  @override
  List<Object?> get props => [order];
}

class OrdersError extends OrdersState {
  const OrdersError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
