import 'package:flutter/material.dart';
import '../../domain/entities/order.dart';

class OrderItemsCard extends StatelessWidget {
  const OrderItemsCard({super.key, required this.items});
  final List<OrderItem> items;

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
              children: [
                const Icon(Icons.inventory_2_outlined, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Items (${items.length})',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.asMap().entries.map((e) => _ItemRow(
                  index: e.key,
                  item: e.value,
                  isLast: e.key == items.length - 1,
                )),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow(
      {required this.index, required this.item, required this.isLast});
  final int index;
  final OrderItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description.isEmpty
                        ? item.type.replaceAll('_', ' ')
                        : item.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.type.replaceAll('_', ' ')}  ·  x${item.quantity}  ·  ${item.weightKg} kg',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  if (item.isFragile || item.isRefrigerated) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (item.isFragile) _tag('Fragile', Colors.orange),
                        if (item.isRefrigerated)
                          _tag('Refrigerated', Colors.blue),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (item.declaredValue != null)
              Text(
                '${item.declaredValue!.toStringAsFixed(0)} ETB',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
          ],
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
      ],
    );
  }

  Widget _tag(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.green,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}
