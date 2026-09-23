import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_order.dart';
import 'create_order_event.dart';
import 'create_order_state.dart';

class CreateOrderBloc extends Bloc<CreateOrderEvent, CreateOrderState> {
  CreateOrderBloc({required this.createOrder}) : super(CreateOrderIdle()) {
    on<SubmitOrderEvent>(_onSubmit);
    on<ResetCreateOrderEvent>((_, emit) => emit(CreateOrderIdle()));
  }

  final CreateOrder createOrder;

  Future<void> _onSubmit(
    SubmitOrderEvent e,
    Emitter<CreateOrderState> emit,
  ) async {
    emit(CreateOrderSubmitting());
    final res = await createOrder(
      sender: e.sender,
      receiver: e.receiver,
      items: e.items,
      paymentParty: e.paymentParty,
      codAmount: e.codAmount,
      sendReceiverLink: e.sendReceiverLink,
    );
    res.fold(
      (l) => emit(CreateOrderError(l.message)),
      (order) => emit(CreateOrderSuccess(order)),
    );
  }
}
