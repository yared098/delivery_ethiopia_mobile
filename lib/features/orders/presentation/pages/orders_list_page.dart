import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../di/service_locator.dart';
import '../../domain/entities/order.dart';
import '../bloc/orders_bloc.dart';
import '../bloc/orders_event.dart';
import '../bloc/orders_state.dart';
import 'order_detail_page.dart';

class OrdersListPage extends StatelessWidget {
  const OrdersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // One bloc instance per page, but shared across the 3 tabs.
    return BlocProvider(
      create: (_) => sl<OrdersBloc>()..add(const LoadOrdersEvent(type: 'all')),
      child: const _OrdersShell(),
    );
  }
}

class _OrdersShell extends StatefulWidget {
  const _OrdersShell();

  @override
  State<_OrdersShell> createState() => _OrdersShellState();
}

class _OrdersShellState extends State<_OrdersShell>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      const types = ['all', 'sent', 'received'];
      context
          .read<OrdersBloc>()
          .add(LoadOrdersEvent(type: types[_tabs.index]));
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Sent'),
            Tab(text: 'Received'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _OrdersList(),
          _OrdersList(),
          _OrdersList(),
        ],
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (context, state) {
        if (state is OrdersLoading || state is OrdersInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is OrdersError) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context
                .read<OrdersBloc>()
                .add(const LoadOrdersEvent(type: 'all')),
          );
        }
        if (state is OrdersLoaded) {
          if (state.orders.isEmpty) {
            return const _EmptyView();
          }
          return RefreshIndicator(
            onRefresh: () async {
              final controller =
                  DefaultTabController.maybeOf(context);
              // reload current tab
              final type = _currentType(context);
              context.read<OrdersBloc>().add(LoadOrdersEvent(type: type));
              // keep the unused variable out
              controller?.index;
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.orders.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) =>
                  _OrderTile(order: state.orders[i]),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  String _currentType(BuildContext context) {
    final tabs = DefaultTabController.maybeOf(context);
    switch (tabs?.index ?? 0) {
      case 1:
        return 'sent';
      case 2:
        return 'received';
      default:
        return 'all';
    }
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});
  final DeliveryOrder order;

  @override
  Widget build(BuildContext context) {
    final title = order.trackingNumber ?? order.id;
    final subtitle =
        '${order.sender.phone} → ${order.receiver.phone}';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          _iconForStatus(order.status),
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(
            children: [
              _StatusChip(status: order.status),
              const SizedBox(width: 8),
              Text(
                '${order.items.length} item(s)',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailPage(id: order.id),
        ),
      ),
    );
  }

  IconData _iconForStatus(OrderStatus s) {
    switch (s) {
      case OrderStatus.delivered:
        return Icons.check_circle_outline;
      case OrderStatus.cancelled:
      case OrderStatus.failed:
      case OrderStatus.returned:
        return Icons.cancel_outlined;
      case OrderStatus.inTransit:
      case OrderStatus.outForDelivery:
      case OrderStatus.pickedUp:
        return Icons.local_shipping_outlined;
      case OrderStatus.pendingPayment:
      case OrderStatus.paid:
        return Icons.payments_outlined;
      case OrderStatus.assigned:
        return Icons.person_pin_circle_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }

  (Color, Color) _colors(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
      case OrderStatus.assigned:
        return (Colors.blue.shade100, Colors.blue.shade800);
      case OrderStatus.pendingPayment:
        return (Colors.orange.shade100, Colors.orange.shade800);
      default:
        return (scheme.surfaceContainerHighest, scheme.onSurface);
    }
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      // Allows pull-to-refresh even when empty
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.inbox_outlined, size: 64, color: Colors.black26),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'No orders yet',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
        const SizedBox(height: 4),
        const Center(
          child: Text(
            'Your deliveries will appear here.',
            style: TextStyle(color: Colors.black45),
          ),
        ),
      ],
    );
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
        Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15),
          ),
        ),
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
