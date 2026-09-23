import 'package:equatable/equatable.dart';
import '../../domain/entities/order.dart';

abstract class CreateOrderEvent extends Equatable {
  const CreateOrderEvent();
  @override
  List<Object?> get props => [];
}

class SubmitOrderEvent extends CreateOrderEvent {
  const SubmitOrderEvent({
    required this.sender,
    required this.receiver,
    required this.items,
    required this.paymentParty,
    this.codAmount = 0,
    this.sendReceiverLink = false,
  });

  final OrderParty sender;
  final OrderParty receiver;
  final List<OrderItem> items;
  final String paymentParty; // SENDER | RECEIVER | SPLIT
  final double codAmount;
  final bool sendReceiverLink;

  @override
  List<Object?> get props =>
      [sender, receiver, items, paymentParty, codAmount, sendReceiverLink];
}

class ResetCreateOrderEvent extends CreateOrderEvent {
  const ResetCreateOrderEvent();
}
