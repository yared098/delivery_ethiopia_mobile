import 'package:flutter/material.dart';
import '../../domain/entities/courier_earning.dart';

class CourierStatsCard extends StatelessWidget {
  final CourierJobsStats stats;
  const CourierStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _Stat(label: 'Assigned', value: '${stats.todayAssigned}'),
                _Stat(label: 'Completed', value: '${stats.todayCompleted}'),
                _Stat(label: 'In progress', value: '${stats.todayInProgress}'),
                _Stat(
                  label: 'Earnings',
                  value: '${stats.todayEarnings.toStringAsFixed(0)} ETB',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
