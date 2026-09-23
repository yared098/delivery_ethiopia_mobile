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
    final current = state;
    // Show the loading state for that tab only. If we already have data for
    // that tab, keep it on screen (background refresh) — no spinner flash.
    final cached = current is OrdersLoaded ? current.forType(e.type) : null;
    if (cached == null || cached.isEmpty) {
      emit(OrdersLoading(forType: e.type));
    }

    final res = await listOrders(type: e.type);
    res.fold(
      (l) => emit(OrdersError(l.message, forType: e.type)),
      (orders) {
        final map = current is OrdersLoaded
            ? Map<String, List<DeliveryOrder>>.from(current.byType)
            : <String, List<DeliveryOrder>>{};
        map[e.type] = orders;
        emit(OrdersLoaded(map));
      },
    );
  }

  Future<void> _onDetail(
    LoadOrderDetailEvent e,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading(forType: '__detail__'));
    final res = await getOrderDetail(e.id);
    res.fold(
      (l) => emit(OrdersError(l.message)),
      (order) => emit(OrderDetailLoaded(order)),
    );
  }
}
