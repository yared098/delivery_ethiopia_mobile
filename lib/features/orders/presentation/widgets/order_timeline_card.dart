import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/order.dart';

class OrderTimelineCard extends StatelessWidget {
  const OrderTimelineCard({super.key, required this.events});
  final List<OrderEventItem> events;

  @override
  Widget build(BuildContext context) {
    final list = [...events]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // newest first
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
                const Icon(Icons.history, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Timeline (${list.length})',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No events yet.',
                  style: TextStyle(color: Colors.black54),
                ),
              )
            else
              ...list.asMap().entries.map((e) => _EventRow(
                    event: e.value,
                    isFirst: e.key == 0,
                    isLast: e.key == list.length - 1,
                  )),
          ],
        ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.isFirst,
    required this.isLast,
  });
  final OrderEventItem event;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = OrderStatus.fromString(event.status);
    final time = DateFormat('MMM d · HH:mm').format(event.createdAt.toLocal());

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left rail with dot + connector
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: isFirst ? scheme.primary : scheme.outlineVariant,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: scheme.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.label,
                    style: TextStyle(
                      fontWeight:
                          isFirst ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  if ((event.note ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.note!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                  if ((event.location ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined,
                            size: 12, color: Colors.black45),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
