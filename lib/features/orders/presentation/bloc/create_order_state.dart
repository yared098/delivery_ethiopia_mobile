import 'package:equatable/equatable.dart';
import '../../domain/entities/order.dart';

abstract class CreateOrderState extends Equatable {
  const CreateOrderState();
  @override
  List<Object?> get props => [];
}

class CreateOrderIdle extends CreateOrderState {}
class CreateOrderSubmitting extends CreateOrderState {}

class CreateOrderSuccess extends CreateOrderState {
  const CreateOrderSuccess(this.order);
  final DeliveryOrder order;
  @override
  List<Object?> get props => [order];
}

class CreateOrderError extends CreateOrderState {
  const CreateOrderError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
