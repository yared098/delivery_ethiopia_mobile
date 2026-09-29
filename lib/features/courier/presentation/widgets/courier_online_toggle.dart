import 'package:flutter/material.dart';
import '../../domain/entities/courier.dart';

class CourierOnlineToggle extends StatelessWidget {
  final Courier courier;
  final ValueChanged<bool> onToggle;
  const CourierOnlineToggle({
    super.key,
    required this.courier,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final online = courier.isOnline;
    return Card(
      color: online ? Colors.green.shade50 : Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: online ? Colors.green : Colors.grey,
              child: Icon(
                online ? Icons.check : Icons.power_settings_new,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    courier.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    online ? 'Online — receiving jobs' : 'Offline',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: online,
              onChanged: onToggle,
            ),
          ],
        ),
      ),
    );
  }
}