import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../di/service_locator.dart';
import '../../domain/entities/courier.dart';
import '../../domain/repositories/courier_repository.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';

class CourierProfilePage extends StatefulWidget {
  const CourierProfilePage({super.key});

  @override
  State<CourierProfilePage> createState() => _CourierProfilePageState();
}

class _CourierProfilePageState extends State<CourierProfilePage> {
  Courier? _courier;
  bool _loading = true;
  bool _initialized = false;

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
      final c = await repo.getMe();
      if (!mounted) return;
      setState(() {
        _courier = c;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log out?'),
        content: const Text(
          'You will be signed out and will need to log in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      context.read<AuthBloc>().add(LogoutEvent());
    }
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
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _courier == null
              ? const _ErrorState()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _ProfileBody(courier: _courier!),
                ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  final Courier courier;
  const _ProfileBody({required this.courier});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _HeroCard(courier: courier),
        const SizedBox(height: 16),
        _StatsRow(courier: courier),
        const SizedBox(height: 20),
        const _SectionLabel('Personal'),
        const SizedBox(height: 8),
        _InfoCard(
          rows: [
            _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: courier.phone),
            _InfoRow(
              icon: Icons.location_city_outlined,
              label: 'Region',
              value: courier.regionName,
            ),
            _InfoRow(
              icon: Icons.store_mall_directory_outlined,
              label: 'Branch',
              value: courier.branchName,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _SectionLabel('Vehicle'),
        const SizedBox(height: 8),
        _InfoCard(
          rows: [
            _InfoRow(
              icon: Icons.directions_car_outlined,
              label: 'Type',
              value: courier.vehicleType,
            ),
            if (courier.vehiclePlate != null)
              _InfoRow(
                icon: Icons.confirmation_number_outlined,
                label: 'Plate',
                value: courier.vehiclePlate!,
              ),
          ],
        ),
        const SizedBox(height: 20),
        const _SectionLabel('Account'),
        const SizedBox(height: 8),
        _InfoCard(
          rows: [
            _InfoRow(
              icon: Icons.verified_user_outlined,
              label: 'Status',
              value: courier.status,
              valueColor: _statusColor(courier.status),
            ),
          ],
        ),
      ],
    );
  }

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'ACTIVE':
        return const Color(0xFF2E7D32);
      case 'INACTIVE':
      case 'SUSPENDED':
        return const Color(0xFFC62828);
      case 'PENDING':
        return const Color(0xFFEF6C00);
      default:
        return Colors.black87;
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Hero card
// ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final Courier courier;
  const _HeroCard({required this.courier});

  @override
  Widget build(BuildContext context) {
    final initial =
        courier.name.isNotEmpty ? courier.name[0].toUpperCase() : '?';

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
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  courier.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  courier.phone,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                _Stars(rating: courier.rating),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final double rating;
  const _Stars({required this.rating});

  @override
  Widget build(BuildContext context) {
    final full = rating.floor();
    final half = (rating - full) >= 0.5;

    return Row(
      children: [
        for (int i = 0; i < 5; i++)
          Icon(
            i < full
                ? Icons.star
                : (i == full && half ? Icons.star_half : Icons.star_border),
            size: 16,
            color: const Color(0xFFFFC107),
          ),
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Stats row
// ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final Courier courier;
  const _StatsRow({required this.courier});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.check_circle_outline,
            label: 'Deliveries',
            value: '${courier.totalDeliveries}',
            color: const Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.cancel_outlined,
            label: 'Failed',
            value: '${courier.totalFailed}',
            color: const Color(0xFFC62828),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Info card
// ─────────────────────────────────────────────────────────────────

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
}

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> rows;
  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            _rowTile(rows[i]),
            if (i < rows.length - 1)
              Divider(
                height: 1,
                indent: 56,
                color: Colors.grey.shade200,
              ),
          ],
        ],
      ),
    );
  }

  Widget _rowTile(_InfoRow r) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blueGrey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(r.icon, size: 16, color: Colors.blueGrey.shade700),
          ),
          const SizedBox(width: 10),
          Text(
            r.label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              r.value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: r.valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Could not load profile',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Please try again later.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
