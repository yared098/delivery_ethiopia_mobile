import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/account.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../orders/presentation/pages/create_order_page.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.onNavigate});

  /// Lets the tab switch the parent's IndexedStack
  /// (0 = Home, 1 = Orders, 2 = Track, 3 = Profile).
  final void Function(int index) onNavigate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deliver Ethiopia'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<AuthBloc>().add(const RefreshMeEvent()),
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final account = state is AuthAuthenticated ? state.account : null;
          return RefreshIndicator(
            onRefresh: () async {
              context.read<AuthBloc>().add(const RefreshMeEvent());
              await Future<void>.delayed(const Duration(milliseconds: 400));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _HeroCard(account: account),
                const SizedBox(height: 20),
                const _SectionTitle('Quick actions'),
                const SizedBox(height: 10),
                _FeatureGrid(
                  items: [
                    _FeatureItem(
                      icon: Icons.add_box_outlined,
                      label: 'Send',
                      color: Colors.green,
                      onTap: () async {
                        final id = await Navigator.push<String?>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CreateOrderPage()),
                        );
                        if (id != null && context.mounted) {
                          onNavigate(1); // jump to Orders
                        }
                      },
                    ),
                    _FeatureItem(
                      icon: Icons.receipt_long_outlined,
                      label: 'Orders',
                      color: Colors.blue,
                      onTap: () => onNavigate(1),
                    ),
                    _FeatureItem(
                      icon: Icons.search_outlined,
                      label: 'Track',
                      color: Colors.orange,
                      onTap: () => onNavigate(2),
                    ),
                    _FeatureItem(
                      icon: Icons.person_outline,
                      label: 'Profile',
                      color: Colors.purple,
                      onTap: () => onNavigate(3),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _SectionTitle('Your account'),
                const SizedBox(height: 10),
                _AccountCard(account: account),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Hero card with gradient
// ═══════════════════════════════════════════════════════════════
class _HeroCard extends StatelessWidget {
  const _HeroCard({this.account});
  final Account? account;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = account?.name?.trim();
    final hasName = name != null && name.isNotEmpty;
    final initial =
        hasName ? name[0].toUpperCase() : '?';

    return Container(
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
            color: scheme.primary.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.22),
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasName ? 'Hi, $name 👋' : 'Welcome 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  account?.phone ?? '—',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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
// Feature grid (2 columns)
// ═══════════════════════════════════════════════════════════════
class _FeatureItem {
  const _FeatureItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.items});
  final List<_FeatureItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      children: items.map((i) => _FeatureTile(item: i)).toList(),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.item});
  final _FeatureItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Account summary
// ═══════════════════════════════════════════════════════════════
class _AccountCard extends StatelessWidget {
  const _AccountCard({this.account});
  final Account? account;

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            _InfoTile(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: account?.phone ?? '—',
            ),
            if ((account?.email ?? '').isNotEmpty)
              _InfoTile(
                icon: Icons.mail_outline,
                label: 'Email',
                value: account!.email!,
              ),
            if ((account?.defaultAddress ?? '').isNotEmpty)
              _InfoTile(
                icon: Icons.location_on_outlined,
                label: 'Default address',
                value: account!.defaultAddress!,
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
