import 'package:flutter/material.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../di/service_locator.dart';

class TrackingTab extends StatefulWidget {
  const TrackingTab({super.key});

  @override
  State<TrackingTab> createState() => _TrackingTabState();
}

class _TrackingTabState extends State<TrackingTab> {
  final _token = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  Future<void> _track() async {
    final token = _token.text.trim();
    if (token.isEmpty) return;
    setState(() {
      _loading = true;
      _result = null;
      _error = null;
    });

    try {
      final dio = sl<DioClient>().dio;
      final res = await dio.get('/public/track/$token');
      setState(() => _result = res.data as Map<String, dynamic>);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track a delivery')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Enter a tracking number or token to see live status.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _token,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _track(),
            decoration: InputDecoration(
              labelText: 'Tracking number or token',
              hintText: 'ETH-2026-Z3ASTG',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: _loading ? null : _track,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          if (_result != null) _ResultCard(data: _result!),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final status = data['status']?.toString() ?? '—';
    final trackingNumber = data['trackingNumber']?.toString() ?? '—';
    final senderName = data['senderName']?.toString() ?? '—';
    final receiverName = data['receiverName']?.toString() ?? '—';

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(trackingNumber,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Chip(label: Text(status)),
            const SizedBox(height: 12),
            _kv('Sender', senderName),
            _kv('Receiver', receiverName),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(k, style: const TextStyle(color: Colors.black54)),
            ),
            Expanded(child: Text(v)),
          ],
        ),
      );
}
