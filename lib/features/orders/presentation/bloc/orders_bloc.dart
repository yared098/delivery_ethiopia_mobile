import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/order.dart';
import '../../domain/usecases/get_order_detail.dart';
import '../../domain/usecases/list_orders.dart';
import 'orders_event.dart';
import 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  OrdersBloc({required this.listOrders, required this.getOrderDetail})
      : super(OrdersInitial()) {
    on<LoadOrdersEvent>(_onList);
    on<LoadOrderDetailEvent>(_onDetail);
  }

  final ListOrders listOrders;
  final GetOrderDetail getOrderDetail;

  Future<void> _onList(LoadOrdersEvent e, Emitter<OrdersState> emit) async {
    emit(OrdersLoading());
    final res = await listOrders(type: e.type);
    res.fold(
      (l) => emit(OrdersError(l.message)),
      (orders) => emit(OrdersLoaded(orders)),
    );
  }

  Future<void> _onDetail(
    LoadOrderDetailEvent e,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());
    final res = await getOrderDetail(e.id);
    res.fold(
      (l) => emit(OrdersError(l.message)),
      (order) => emit(OrderDetailLoaded(order)),
    );
  }
}
