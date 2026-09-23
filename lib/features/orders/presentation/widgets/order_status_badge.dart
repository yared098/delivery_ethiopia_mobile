import 'package:flutter/material.dart';
import '../../domain/entities/order.dart';

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status, this.compact = false});
  final OrderStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(), size: compact ? 12 : 14, color: fg),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 11 : 13,
            ),
          ),
        ],
      ),
    );
  }

  IconData _icon() {
    switch (status) {
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.cancelled:
      case OrderStatus.failed:
      case OrderStatus.returned:
        return Icons.cancel;
      case OrderStatus.inTransit:
      case OrderStatus.outForDelivery:
        return Icons.local_shipping;
      case OrderStatus.pickedUp:
        return Icons.inventory_2;
      case OrderStatus.assigned:
        return Icons.person_pin_circle;
      case OrderStatus.pendingPayment:
        return Icons.hourglass_top;
      case OrderStatus.paid:
        return Icons.payments;
      case OrderStatus.awaitingReceiverLocation:
        return Icons.location_searching;
      case OrderStatus.draft:
        return Icons.edit_note;
    }
  }

  (Color, Color) _colors() {
    switch (status) {
      case OrderStatus.delivered:
        return (Colors.green.shade100, Colors.green.shade800);
      case OrderStatus.cancelled:
      case OrderStatus.failed:
      case OrderStatus.returned:
        return (Colors.red.shade100, Colors.red.shade800);
      case OrderStatus.inTransit:
      case OrderStatus.outForDelivery:
      case OrderStatus.pickedUp:
        return (Colors.blue.shade100, Colors.blue.shade800);
      case OrderStatus.assigned:
        return (Colors.indigo.shade100, Colors.indigo.shade800);
      case OrderStatus.pendingPayment:
        return (Colors.orange.shade100, Colors.orange.shade800);
      case OrderStatus.paid:
        return (Colors.teal.shade100, Colors.teal.shade800);
      case OrderStatus.awaitingReceiverLocation:
        return (Colors.amber.shade100, Colors.amber.shade900);
      case OrderStatus.draft:
        return (Colors.grey.shade200, Colors.grey.shade800);
    }
  }
}
