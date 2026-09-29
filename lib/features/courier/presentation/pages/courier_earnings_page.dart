import 'package:flutter/material.dart';

import '../../../../di/service_locator.dart';
import '../../domain/entities/courier_earning.dart';
import '../../domain/repositories/courier_repository.dart';

class CourierEarningsPage extends StatefulWidget {
  const CourierEarningsPage({super.key});

  @override
  State<CourierEarningsPage> createState() => _CourierEarningsPageState();
}

class _CourierEarningsPageState extends State<CourierEarningsPage> {
  CourierEarningsSummary? _summary;
  List<CourierEarning> _earnings = [];
  bool _loading = true;
  bool _initialized = false;

  /// null = All, otherwise the status string.
  String? _filter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

  Future<void> _load() async {
    final repo = sl<CourierRepository>();
    try {
      final summary = await repo.getEarningsSummary();
      final earnings = await repo.listEarnings();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _earnings = earnings;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  List<CourierEarning> get _filtered {
    if (_filter == null) return _earnings;
    return _earnings
        .where((e) => e.status.toUpperCase() == _filter!.toUpperCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Earnings',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  if (_summary != null) _heroCard(_summary!),
                  const SizedBox(height: 24),

                  // ── Filter chips ─────────────────────────────────
                  if (_earnings.isNotEmpty) ...[
                    _FilterChips(
                      earnings: _earnings,
                      selected: _filter,
                      onChanged: (v) => setState(() => _filter = v),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Recent list ──────────────────────────────────
                  Row(
                    children: [
                      const Text(
                        'Recent earnings',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_filtered.length}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_filtered.isEmpty)
                    const _EmptyState()
                  else
                    ..._filtered.map((e) => _earningTile(e)),
                ],
              ),
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Hero card — total balance + breakdown
  // ─────────────────────────────────────────────────────────────────

  Widget _heroCard(CourierEarningsSummary s) {
    final total = s.pending + s.released + s.paid;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'TOTAL EARNINGS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${total.toStringAsFixed(0)} ETB',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 16),
          Row(
            children: [
              _statCol('Pending', s.pending, const Color(0xFFFFB74D)),
              _divider(),
              _statCol('Released', s.released, const Color(0xFF64B5F6)),
              _divider(),
              _statCol('Paid', s.paid, const Color(0xFF81C784)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCol(String label, double amount, Color dot) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount.toStringAsFixed(0),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: Colors.white.withValues(alpha: 0.12),
      );

  // ─────────────────────────────────────────────────────────────────
  // Earning tile
  // ─────────────────────────────────────────────────────────────────

  Widget _earningTile(CourierEarning e) {
    final isPaid = e.status.toUpperCase() == 'PAID';
    final isPending = e.status.toUpperCase() == 'PENDING';
    final color = isPaid
        ? const Color(0xFF2E7D32)
        : isPending
            ? const Color(0xFFEF6C00)
            : const Color(0xFF1565C0);
    final icon = isPaid
        ? Icons.check_circle
        : isPending
            ? Icons.schedule
            : Icons.arrow_circle_down;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          '${e.amount.toStringAsFixed(0)} ETB',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            e.trackingNumber ?? e.description ?? e.type,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            e.status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Filter chips
// ─────────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final List<CourierEarning> earnings;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _FilterChips({
    required this.earnings,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Unique statuses from the data, plus "All".
    final statuses = <String>{
      for (final e in earnings) e.status.toUpperCase(),
    }.toList()
      ..sort();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('All', selected == null, () => onChanged(null)),
          for (final s in statuses) ...[
            const SizedBox(width: 8),
            _chip(s, selected == s, () => onChanged(s)),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF203A43) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? const Color(0xFF203A43) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : Colors.grey.shade700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No earnings yet',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Completed deliveries will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
