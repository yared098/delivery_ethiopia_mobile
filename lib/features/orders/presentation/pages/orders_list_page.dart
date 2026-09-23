import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../di/service_locator.dart';
import '../../domain/entities/order.dart';
import '../bloc/orders_bloc.dart';
import '../bloc/orders_event.dart';
import '../bloc/orders_state.dart';
import '../widgets/order_status_badge.dart';
import 'create_order_page.dart';
import 'order_detail_page.dart';

class OrdersListPage extends StatelessWidget {
  const OrdersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrdersBloc>(),
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

  static const _types = ['all', 'sent', 'received'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _types.length, vsync: this);
    // Kick off only the first tab
    context.read<OrdersBloc>().add(LoadOrdersEvent(type: _types.first));
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      final t = _types[_tabs.index];
      final state = context.read<OrdersBloc>().state;
      // Only fetch the first time we visit this tab
      final hasData = state is OrdersLoaded && state.byType.containsKey(t);
      if (!hasData) {
        context.read<OrdersBloc>().add(LoadOrdersEvent(type: t));
      }
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
        children: _types.map((t) => _OrdersTab(type: t)).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreateOrderPage()),
          );
          if (created == true && context.mounted) {
            context.read<OrdersBloc>().add(const LoadOrdersEvent(type: 'all'));
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New order'),
      ),
    );
  }
}

/// One tab — knows its own `type` so refresh works correctly.
class _OrdersTab extends StatelessWidget {
  const _OrdersTab({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<OrdersBloc, OrdersState, OrdersState>(
      selector: (s) => s,
      builder: (context, state) {
        // Loading only blocks us if we have no cached data for this tab yet.
        final cached = state is OrdersLoaded ? state.forType(type) : null;
        final isLoading =
            state is OrdersLoading && (state.forType == type) && (cached == null);

        if (isLoading) {
          return const _SkeletonList();
        }

        if (state is OrdersError && state.forType == type) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context
                .read<OrdersBloc>()
                .add(LoadOrdersEvent(type: type)),
          );
        }

        if (cached == null) {
          // Not loaded yet — kick off and show skeleton
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            final s = context.read<OrdersBloc>().state;
            final has = s is OrdersLoaded && s.byType.containsKey(type);
            if (!has) {
              context.read<OrdersBloc>().add(LoadOrdersEvent(type: type));
            }
          });
          return const _SkeletonList();
        }

        if (cached.isEmpty) {
          return _EmptyView(onRefresh: () async {
            context.read<OrdersBloc>().add(LoadOrdersEvent(type: type));
          });
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<OrdersBloc>().add(LoadOrdersEvent(type: type));
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            itemCount: cached.length,
            itemBuilder: (_, i) => _OrderCard(
              order: cached[i],
            ),
          ),
        );
      },
    );
  }
}

/// Pretty card list item.
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final DeliveryOrder order;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailPage(id: order.id),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.trackingNumber ?? order.id,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    OrderStatusBadge(status: order.status, compact: true),
                  ],
                ),
                const SizedBox(height: 10),
                _Route(
                  from: order.sender.name ?? order.sender.phone,
                  to: order.receiver.name ?? order.receiver.phone,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _pill(Icons.inventory_2_outlined,
                        '${order.items.length} item${order.items.length == 1 ? '' : 's'}'),
                    if (order.totalWeightKg > 0) ...[
                      const SizedBox(width: 8),
                      _pill(Icons.scale_outlined,
                          '${order.totalWeightKg.toStringAsFixed(1)} kg'),
                    ],
                    const Spacer(),
                    Text(
                      _amountLabel(order),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _amountLabel(DeliveryOrder order) {
    if (order.codAmount > 0) {
      return 'COD ${order.codAmount.toStringAsFixed(0)} ETB';
    }
    if (order.deliveryFee > 0) {
      return '${order.deliveryFee.toStringAsFixed(0)} ETB';
    }
    return '';
  }

  Widget _pill(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12),
            const SizedBox(width: 4),
            Text(text, style: const TextStyle(fontSize: 11)),
          ],
        ),
      );
}

class _Route extends StatelessWidget {
  const _Route({required this.from, required this.to});
  final String from;
  final String to;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.trip_origin, size: 12, color: Colors.green),
        const SizedBox(width: 6),
        Expanded(
          child: Text(from,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.arrow_right_alt, size: 16, color: Colors.black38),
        ),
        const Icon(Icons.place, size: 12, color: Colors.orange),
        const SizedBox(width: 6),
        Expanded(
          child: Text(to,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}

/// Skeleton list — matches the card shape so the swap is seamless.
class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      itemCount: 6,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Icon(Icons.inbox_outlined, size: 64, color: Colors.black26),
          SizedBox(height: 12),
          Center(
            child: Text(
              'No orders yet',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
          SizedBox(height: 4),
          Center(
            child: Text(
              'Your deliveries will appear here.',
              style: TextStyle(color: Colors.black45),
            ),
          ),
        ],
      ),
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
