import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/order.dart';

class OrderPartyCard extends StatelessWidget {
  const OrderPartyCard({
    super.key,
    required this.title,
    required this.party,
    required this.icon,
    this.color,
  });

  final String title;
  final OrderParty party;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
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
                CircleAvatar(
                  radius: 16,
                  backgroundColor: c.withOpacity(0.15),
                  child: Icon(icon, size: 18, color: c),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if ((party.name ?? '').trim().isNotEmpty)
              _line(Icons.person_outline, party.name!),
            _line(
              Icons.phone_outlined,
              party.phone,
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: party.phone));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Phone copied'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
            if ((party.address ?? '').trim().isNotEmpty)
              _line(Icons.location_on_outlined, party.address!),
          ],
        ),
      ),
    );
  }

  Widget _line(IconData icon, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
          ],
        ),
      ),
    );
  }
}
