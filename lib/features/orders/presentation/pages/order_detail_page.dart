import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../di/service_locator.dart';
import '../../domain/entities/order.dart';
import '../bloc/orders_bloc.dart';
import '../bloc/orders_event.dart';
import '../bloc/orders_state.dart';
import '../widgets/order_courier_card.dart';
import '../widgets/order_items_card.dart';
import '../widgets/order_party_card.dart';
import '../widgets/order_status_badge.dart';
import '../widgets/order_timeline_card.dart';

class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrdersBloc>()..add(LoadOrderDetailEvent(id)),
      child: const _OrderDetailView(),
    );
  }
}

class _OrderDetailView extends StatelessWidget {
  const _OrderDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<OrdersBloc, OrdersState>(
        builder: (context, state) {
          if (state is OrdersLoading || state is OrdersInitial) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (state is OrdersError) {
            return Scaffold(
              appBar: AppBar(),
              body: _ErrorView(
                message: state.message,
                onRetry: () => context
                    .read<OrdersBloc>()
                    .add(LoadOrderDetailEvent(sl<OrdersBloc>().state is OrderDetailLoaded
                        ? (sl<OrdersBloc>().state as OrderDetailLoaded).order.id
                        : '')),
              ),
            );
          }
          if (state is! OrderDetailLoaded) {
            return const Scaffold(body: SizedBox.shrink());
          }
          return _OrderDetailBody(order: state.order);
        },
      ),
    );
  }
}

class _OrderDetailBody extends StatelessWidget {
  const _OrderDetailBody({required this.order});
  final DeliveryOrder order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(order.trackingNumber ?? 'Order'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy tracking number',
            onPressed: order.trackingNumber == null
                ? null
                : () async {
                    await Clipboard.setData(
                        ClipboardData(text: order.trackingNumber!));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tracking number copied'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context
              .read<OrdersBloc>()
              .add(LoadOrderDetailEvent(order.id));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Header(order: order),
            const SizedBox(height: 20),
            if (order.courier != null) ...[
              OrderCourierCard(courier: order.courier!),
              const SizedBox(height: 16),
            ],
            OrderPartyCard(
              title: 'SENDER',
              party: order.sender,
              icon: Icons.person_pin_circle_outlined,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            OrderPartyCard(
              title: 'RECEIVER',
              party: order.receiver,
              icon: Icons.person_pin_outlined,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            OrderItemsCard(items: order.items),
            const SizedBox(height: 16),
            _PaymentCard(order: order),
            const SizedBox(height: 16),
            if (order.events.isNotEmpty) ...[
              OrderTimelineCard(events: order.events),
              const SizedBox(height: 16),
            ],
            _MetaCard(order: order),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.order});
  final DeliveryOrder order;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.trackingNumber ?? order.id,
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                OrderStatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _etaText(),
              style: TextStyle(
                color: scheme.onPrimary.withOpacity(0.85),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _etaText() {
    if (order.status == OrderStatus.delivered) {
      if (order.deliveredAt != null) {
        return 'Delivered on ${_fmt(order.deliveredAt!)}';
      }
      return 'Delivered';
    }
    if (order.status == OrderStatus.cancelled) {
      return order.cancelledAt != null
          ? 'Cancelled on ${_fmt(order.cancelledAt!)}'
          : 'Cancelled';
    }
    if (order.estimatedArrival != null) {
      return 'Estimated arrival ${_fmt(order.estimatedArrival!)}';
    }
    return order.status.label;
  }

  String _fmt(DateTime d) {
    final local = d.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.order});
  final DeliveryOrder order;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.payments_outlined, size: 18),
                SizedBox(width: 8),
                Text('Payment',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            _row('Delivery fee',
                '${order.deliveryFee.toStringAsFixed(0)} ETB'),
            _row('Payment party', order.paymentParty),
            if (order.codAmount > 0)
              _row('COD amount', '${order.codAmount.toStringAsFixed(0)} ETB'),
            if ((order.paymentStatus ?? '').isNotEmpty)
              _row('Status', order.paymentStatus!),
            if ((order.paymentMethod ?? '').isNotEmpty)
              _row('Method', order.paymentMethod!),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 13, color: Colors.black54)),
            ),
            Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.order});
  final DeliveryOrder order;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.info_outline, size: 18),
                SizedBox(width: 8),
                Text('Details',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            if (order.totalWeightKg > 0)
              _row('Total weight', '${order.totalWeightKg} kg'),
            if (order.distanceKm != null)
              _row('Distance', '${order.distanceKm!.toStringAsFixed(1)} km'),
            if (order.isFragile) _row('Fragile', 'Yes'),
            if (order.isRefrigerated) _row('Refrigerated', 'Yes'),
            if ((order.packageDescription ?? '').isNotEmpty)
              _row('Package', order.packageDescription!),
            if (order.createdAt != null)
              _row('Created', _short(order.createdAt!)),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(label,
                  style:
                      const TextStyle(fontSize: 13, color: Colors.black54)),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

  String _short(DateTime d) {
    final l = d.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')} '
        '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
        const SizedBox(height: 12),
        Center(child: Text(message, textAlign: TextAlign.center)),
        const SizedBox(height: 20),
        Center(
          child: FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ),
      ],
    );
  }
}
