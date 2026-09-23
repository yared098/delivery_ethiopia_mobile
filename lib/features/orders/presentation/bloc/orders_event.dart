import 'package:equatable/equatable.dart';

abstract class OrdersEvent extends Equatable {
  const OrdersEvent();
  @override
  List<Object?> get props => [];
}

class LoadOrdersEvent extends OrdersEvent {
  const LoadOrdersEvent({this.type = 'all'});
  final String type;
  @override
  List<Object?> get props => [type];
}

class LoadOrderDetailEvent extends OrdersEvent {
  const LoadOrderDetailEvent(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}
