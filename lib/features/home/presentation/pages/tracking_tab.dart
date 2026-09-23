import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../di/service_locator.dart';
import '../../../orders/presentation/widgets/order_status_badge.dart';
import '../../../orders/domain/entities/order.dart';

class TrackingTab extends StatefulWidget {
  const TrackingTab({super.key});

  @override
  State<TrackingTab> createState() => _TrackingTabState();
}

class _TrackingTabState extends State<TrackingTab> {
  final _token = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();

  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void dispose() {
    _token.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _track() async {
    final token = _token.text.trim();
    if (token.isEmpty) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();

    setState(() {
      _loading = true;
      _result = null;
      _error = null;
    });

    try {
      final dio = sl<DioClient>().dio;
      final res = await dio.get('/public/track/$token');
      final data = res.data;
      if (data is Map<String, dynamic>) {
        setState(() => _result = data);
      } else if (data is Map) {
        setState(() => _result = data.cast<String, dynamic>());
      } else {
        setState(() => _error = 'Unexpected response from server');
      }
    } catch (e) {
      final msg = e.toString();
      setState(() => _error = _friendly(msg));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendly(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('404')) return 'No shipment found for that number.';
    if (lower.contains('400')) return 'Invalid tracking number or token.';
    if (lower.contains('connection')) {
      return 'Cannot reach server. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }

  void _clear() {
    _token.clear();
    _focus.requestFocus();
    setState(() {
      _result = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track a delivery'),
        centerTitle: false,
        actions: [
          if (_result != null || _error != null)
            IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.refresh),
              onPressed: _clear,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _Hero(),
            const SizedBox(height: 20),
            _InputCard(
              controller: _token,
              focusNode: _focus,
              loading: _loading,
              onTrack: _track,
              onClear: _clear,
            ),
            const SizedBox(height: 20),
            if (_loading) _Loading(),
            if (_error != null) _ErrorCard(message: _error!),
            if (_result != null) _ResultBlock(data: _result!),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Tip: tracking numbers look like ETH-2026-XXXXXX',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withOpacity(0.55),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Hero
// ═══════════════════════════════════════════════════════════════
class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, Colors.black, 0.25) ?? scheme.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Where is my package?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Enter a tracking number to see live status.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Input card
// ═══════════════════════════════════════════════════════════════
class _InputCard extends StatefulWidget {
  const _InputCard({
    required this.controller,
    required this.focusNode,
    required this.loading,
    required this.onTrack,
    required this.onClear,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool loading;
  final VoidCallback onTrack;
  final VoidCallback onClear;

  @override
  State<_InputCard> createState() => _InputCardState();
}

class _InputCardState extends State<_InputCard> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  void _onChange() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasText = widget.controller.text.trim().isNotEmpty;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              enabled: !widget.loading,
              textInputAction: TextInputAction.search,
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => widget.onTrack(),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[A-Za-z0-9\-]'),
                ),
              ],
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
              decoration: InputDecoration(
                labelText: 'Tracking number or token',
                hintText: 'ETH-2026-Z3ASTG',
                prefixIcon: const Icon(Icons.qr_code_2),
                suffixIcon: hasText
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: 'Clear',
                        onPressed: widget.loading ? null : widget.onClear,
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (widget.loading || !hasText) ? null : widget.onTrack,
                icon: widget.loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: const Text('Track shipment'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Loading skeleton
// ═══════════════════════════════════════════════════════════════
class _Loading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Column(
      children: [
        Container(
          height: 110,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Error
// ═══════════════════════════════════════════════════════════════
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Result block
// ═══════════════════════════════════════════════════════════════
class _ResultBlock extends StatelessWidget {
  const _ResultBlock({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final trackingNumber = data['trackingNumber']?.toString();
    final statusRaw = data['status']?.toString() ?? 'UNKNOWN';
    final status = OrderStatus.fromString(statusRaw);
    final senderName = data['senderName']?.toString();
    final receiverName = data['receiverName']?.toString();
    final courierName = data['courierName']?.toString() ??
        (data['courier'] is Map
            ? (data['courier'] as Map)['name']?.toString()
            : null);
    final eta = data['estimatedArrival']?.toString();
    final events = (data['events'] as List?) ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderCard(
          trackingNumber: trackingNumber,
          status: status,
          eta: eta,
        ),
        if (senderName != null || receiverName != null || courierName != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _PartiesCard(
              senderName: senderName,
              receiverName: receiverName,
              courierName: courierName,
            ),
          ),
        if (events.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _TimelineCard(events: events),
          ),
        // ── Placeholder for future map ──
        // See "Part 2" for the Google Maps insertion point.
        // Padding(
        //   padding: const EdgeInsets.only(top: 12),
        //   child: _MapCard(data: data),
        // ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.trackingNumber,
    required this.status,
    required this.eta,
  });
  final String? trackingNumber;
  final OrderStatus status;
  final String? eta;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, Colors.black, 0.22) ?? scheme.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  trackingNumber ?? '—',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Copy',
                onPressed: trackingNumber == null
                    ? null
                    : () {
                        Clipboard.setData(ClipboardData(text: trackingNumber!));
                        ScaffoldMessenger.of(context)
                          ..clearSnackBars()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text('Tracking number copied'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 1),
                            ),
                          );
                      },
                icon: const Icon(Icons.copy, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 6),
          OrderStatusBadge(status: status),
          if ((eta ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.schedule, size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  'ETA $eta',
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PartiesCard extends StatelessWidget {
  const _PartiesCard({
    this.senderName,
    this.receiverName,
    this.courierName,
  });
  final String? senderName;
  final String? receiverName;
  final String? courierName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('People',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 10),
            if (senderName != null)
              _row(Icons.person_pin_circle, 'From', senderName!),
            if (receiverName != null) _row(Icons.place, 'To', receiverName!),
            if (courierName != null)
              _row(Icons.delivery_dining, 'Courier', courierName!),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.black54),
            const SizedBox(width: 10),
            SizedBox(
              width: 66,
              child: Text(label,
                  style: const TextStyle(fontSize: 13, color: Colors.black54)),
            ),
            Expanded(
              child: Text(
                value,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.events});
  final List events;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final parsed =
        events.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
          ..sort((a, b) {
            final da = DateTime.tryParse((a['createdAt'] ?? '') as String) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final db = DateTime.tryParse((b['createdAt'] ?? '') as String) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return db.compareTo(da);
          });

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Timeline (${parsed.length})',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 12),
            ...parsed.asMap().entries.map((e) {
              final isFirst = e.key == 0;
              final isLast = e.key == parsed.length - 1;
              final ev = e.value;
              final st = OrderStatus.fromString((ev['status'] ?? '') as String);
              final note = ev['note']?.toString();
              final ts = DateTime.tryParse((ev['createdAt'] ?? '') as String);

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: isFirst
                                ? scheme.primary
                                : scheme.outlineVariant,
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
                              st.label,
                              style: TextStyle(
                                fontWeight:
                                    isFirst ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            if (ts != null)
                              Text(
                                _fmt(ts),
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.black54),
                              ),
                            if (note != null && note.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(note,
                                    style: const TextStyle(fontSize: 12)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime d) {
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)} · ${two(l.hour)}:${two(l.minute)}';
  }
}
