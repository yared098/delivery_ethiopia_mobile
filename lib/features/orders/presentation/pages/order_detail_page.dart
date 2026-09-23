import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../di/service_locator.dart';
import '../bloc/orders_bloc.dart';
import '../bloc/orders_event.dart';
import '../bloc/orders_state.dart';

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
      appBar: AppBar(title: const Text('Order Detail')),
      body: BlocBuilder<OrdersBloc, OrdersState>(
        builder: (context, state) {
          if (state is OrdersLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is OrdersError) {
            return Center(child: Text(state.message));
          }
          if (state is OrderDetailLoaded) {
            final o = state.order;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(o.trackingNumber ?? o.id,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Chip(label: Text(o.status.label)),
                const Divider(height: 32),
                const Text('Sender', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${o.sender.name ?? '-'} • ${o.sender.phone}'),
                const SizedBox(height: 12),
                const Text('Receiver', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${o.receiver.name ?? '-'} • ${o.receiver.phone}'),
                const Divider(height: 32),
                const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
                ...o.items.map((i) => ListTile(
                  title: Text(i.description),
                  subtitle: Text('${i.type} • ${i.weightKg} kg'),
                  trailing: Text('x${i.quantity}'),
                )),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
