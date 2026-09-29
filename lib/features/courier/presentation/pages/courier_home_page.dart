import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../di/service_locator.dart';
import '../../domain/entities/courier_job.dart';
import '../../domain/repositories/courier_repository.dart';
import '../bloc/courier_home_bloc.dart';
import '../bloc/courier_home_event.dart';
import '../bloc/courier_home_state.dart';
import '../widgets/courier_job_card.dart';
import '../widgets/courier_stats_card.dart';
import '../widgets/courier_online_toggle.dart';
import 'courier_job_detail_page.dart';
import 'courier_earnings_page.dart';
import 'courier_profile_page.dart';

class CourierHomePage extends StatelessWidget {
  const CourierHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = sl<CourierRepository>();

    return BlocProvider(
      create: (_) => CourierHomeBloc(repo)..add(LoadCourierHome()),
      child: const _CourierHomeView(),
    );
  }
}

class _CourierHomeView extends StatelessWidget {
  const _CourierHomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: BlocBuilder<CourierHomeBloc, CourierHomeState>(
        builder: (context, state) {
          if (state is CourierHomeLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CourierHomeError) {
            return SafeArea(
              child: _ErrorView(
                message: state.message,
                onRetry: () =>
                    context.read<CourierHomeBloc>().add(LoadCourierHome()),
              ),
            );
          }

          if (state is CourierHomeLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<CourierHomeBloc>().add(RefreshCourierHome());
              },
              child: _LoadedView(state: state),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Loaded view
// ─────────────────────────────────────────────────────────────────

class _LoadedView extends StatefulWidget {
  final CourierHomeLoaded state;
  const _LoadedView({required this.state});

  @override
  State<_LoadedView> createState() => _LoadedViewState();
}

class _LoadedViewState extends State<_LoadedView> {
  int _tab = 0; // 0 = All, 1 = New, 2 = In progress, 3 = Done

  List<CourierJob> get _newJobs => widget.state.jobs
      .where((j) => const {'ASSIGNED', 'ACCEPTED', 'PENDING'}
          .contains(j.status.toUpperCase()))
      .toList();

  List<CourierJob> get _inProgressJobs => widget.state.jobs
      .where((j) => const {
            'PICKED_UP',
            'IN_TRANSIT',
            'OUT_FOR_DELIVERY',
            'AT_DROPOFF',
          }.contains(j.status.toUpperCase()))
      .toList();

  List<CourierJob> get _doneJobs => widget.state.jobs
      .where((j) => const {'DELIVERED', 'COMPLETED', 'CANCELLED', 'FAILED'}
          .contains(j.status.toUpperCase()))
      .toList();

  List<CourierJob> get _visible {
    switch (_tab) {
      case 1:
        return _newJobs;
      case 2:
        return _inProgressJobs;
      case 3:
        return _doneJobs;
      default:
        return widget.state.jobs;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final courier = state.courier;
    final isOnline = courier.status.toUpperCase() == 'ONLINE' ||
        courier.status.toUpperCase() == 'ACTIVE';

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // ── Hero header ────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _Header(
            name: courier.name,
            isOnline: isOnline,
            onEarningsTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CourierEarningsPage(),
              ),
            ),
            onProfileTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CourierProfilePage(),
              ),
            ),
          ),
        ),

        // ── Online toggle + stats ──────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              children: [
                CourierOnlineToggle(
                  courier: courier,
                  onToggle: (val) {
                    context.read<CourierHomeBloc>().add(
                          ToggleCourierOnline(
                            lat: 9.0192,
                            lng: 38.7525,
                            goOnline: val,
                          ),
                        );
                  },
                ),
                const SizedBox(height: 16),
                CourierStatsCard(stats: state.stats),
              ],
            ),
          ),
        ),

        // ── Tabs ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 0, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _TabChip(
                    label: 'All',
                    count: state.jobs.length,
                    active: _tab == 0,
                    color: const Color(0xFF37474F),
                    onTap: () => setState(() => _tab = 0),
                  ),
                  const SizedBox(width: 8),
                  _TabChip(
                    label: 'New',
                    count: _newJobs.length,
                    active: _tab == 1,
                    color: const Color(0xFFEF6C00),
                    onTap: () => setState(() => _tab = 1),
                  ),
                  const SizedBox(width: 8),
                  _TabChip(
                    label: 'In progress',
                    count: _inProgressJobs.length,
                    active: _tab == 2,
                    color: const Color(0xFF1565C0),
                    onTap: () => setState(() => _tab = 2),
                  ),
                  const SizedBox(width: 8),
                  _TabChip(
                    label: 'Done',
                    count: _doneJobs.length,
                    active: _tab == 3,
                    color: const Color(0xFF2E7D32),
                    onTap: () => setState(() => _tab = 3),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ),

        // ── Job list ──────────────────────────────────────────────
        if (_visible.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: _EmptyJobs(),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final job = _visible[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Stack(
                      children: [
                        CourierJobCard(
                          job: job,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CourierJobDetailPage(jobId: job.id),
                            ),
                          ),
                        ),
                        // Priority number badge
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color:
                                  _tabColor(job.status).withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                childCount: _visible.length,
              ),
            ),
          ),
      ],
    );
  }

  Color _tabColor(String status) {
    final s = status.toUpperCase();
    if (const {'ASSIGNED', 'ACCEPTED', 'PENDING'}.contains(s)) {
      return const Color(0xFFEF6C00);
    }
    if (const {
      'PICKED_UP',
      'IN_TRANSIT',
      'OUT_FOR_DELIVERY',
      'AT_DROPOFF',
    }.contains(s)) {
      return const Color(0xFF1565C0);
    }
    return const Color(0xFF2E7D32);
  }
}

// ─────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String name;
  final bool isOnline;
  final VoidCallback onEarningsTap;
  final VoidCallback onProfileTap;

  const _Header({
    required this.name,
    required this.isOnline,
    required this.onEarningsTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final firstName = name.split(' ').first;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF203A43), Color(0xFF2C5364)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF203A43).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, $firstName 👋',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isOnline
                              ? const Color(0xFF2E7D32)
                              : Colors.grey.shade400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isOnline
                              ? const Color(0xFF2E7D32)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Earnings',
              onPressed: onEarningsTap,
              icon: const Icon(Icons.attach_money),
              style: IconButton.styleFrom(
                backgroundColor: Colors.green.withValues(alpha: 0.1),
                foregroundColor: const Color(0xFF2E7D32),
              ),
            ),
            IconButton(
              tooltip: 'Profile',
              onPressed: onProfileTap,
              icon: const Icon(Icons.person_outline),
              style: IconButton.styleFrom(
                backgroundColor: Colors.blueGrey.withValues(alpha: 0.1),
                foregroundColor: Colors.blueGrey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Tab chip
// ─────────────────────────────────────────────────────────────────

class _TabChip extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.count,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? color : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active ? color : Colors.grey.shade300,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white.withValues(alpha: 0.25)
                    : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Empty / error
// ─────────────────────────────────────────────────────────────────

class _EmptyJobs extends StatelessWidget {
  const _EmptyJobs();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.blueGrey.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inbox_outlined,
                size: 34, color: Colors.blueGrey.shade400),
          ),
          const SizedBox(height: 16),
          const Text(
            'No active jobs',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'New deliveries will show up here\nwhen you go online.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded,
                  size: 38, color: Colors.red.shade400),
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
