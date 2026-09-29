import 'package:flutter/material.dart';
import '../../domain/entities/courier_job.dart';

class CourierJobCard extends StatelessWidget {
  final CourierJob job;
  final VoidCallback onTap;
  const CourierJobCard({super.key, required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    job.trackingNumber,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Chip(
                    label: Text(
                      job.status.replaceAll('_', ' '),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.blue),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.senderAddress ?? 'Unknown sender',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.flag, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.receiverAddress ?? 'Unknown receiver',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('${job.totalWeightKg} kg'),
                  if (job.distanceKm != null) ...[
                    const SizedBox(width: 12),
                    Text('${job.distanceKm!.toStringAsFixed(1)} km'),
                  ],
                  const Spacer(),
                  Text(
                    '${job.courierEarning.toStringAsFixed(0)} ETB',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
