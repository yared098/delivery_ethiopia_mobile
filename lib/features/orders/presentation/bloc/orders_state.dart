import 'package:equatable/equatable.dart';
import '../../domain/entities/order.dart';

abstract class OrdersState extends Equatable {
  const OrdersState();
  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {}

/// Loading only for a specific tab (keeps other tabs' cached data on screen).
class OrdersLoading extends OrdersState {
  const OrdersLoading({this.forType = 'all'});
  final String forType;
  @override
  List<Object?> get props => [forType];
}

/// Data keyed by tab type so switching tabs is instant.
class OrdersLoaded extends OrdersState {
  const OrdersLoaded(this.byType);
  final Map<String, List<DeliveryOrder>> byType;

  List<DeliveryOrder> forType(String type) => byType[type] ?? const [];

  OrdersLoaded copyWithType(String type, List<DeliveryOrder> orders) =>
      OrdersLoaded({...byType, type: orders});

  @override
  List<Object?> get props => [byType];
}

class OrderDetailLoaded extends OrdersState {
  const OrderDetailLoaded(this.order);
  final DeliveryOrder order;
  @override
  List<Object?> get props => [order];
}

class OrdersError extends OrdersState {
  const OrdersError(this.message, {this.forType});
  final String message;
  final String? forType;
  @override
  List<Object?> get props => [message, forType];
}
