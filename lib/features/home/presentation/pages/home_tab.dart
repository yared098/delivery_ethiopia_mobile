import 'package:deliver_ethiopia/features/orders/presentation/pages/create_order_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/account.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deliver Ethiopia'),
        centerTitle: false,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final account = state is AuthAuthenticated ? state.account : null;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _Greeting(account: account),
              const SizedBox(height: 24),
              const _SectionTitle('Quick actions'),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.add_box_outlined,
                title: 'Send a package',
                subtitle: 'Create a new delivery order',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateOrderPage()),
                ),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.qr_code_scanner,
                title: 'Track by number',
                subtitle: 'Enter a tracking number or token',
                onTap: () => _showSnack(context, 'Use the Track tab below'),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.history,
                title: 'My orders',
                subtitle: 'See sent and received deliveries',
                onTap: () => _showSnack(context, 'Use the Orders tab below'),
              ),
              const SizedBox(height: 32),
              const _SectionTitle('Account'),
              const SizedBox(height: 12),
              _InfoTile(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: account?.phone ?? '—',
              ),
              if (account?.email != null && account!.email!.isNotEmpty)
                _InfoTile(
                  icon: Icons.mail_outline,
                  label: 'Email',
                  value: account.email!,
                ),
              if (account?.defaultAddress != null &&
                  account!.defaultAddress!.isNotEmpty)
                _InfoTile(
                  icon: Icons.location_on_outlined,
                  label: 'Default address',
                  value: account.defaultAddress!,
                ),
            ],
          );
        },
      ),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({this.account});
  final Account? account;

  @override
  Widget build(BuildContext context) {
    final name = account?.name?.trim();
    final greeting =
        name == null || name.isEmpty ? 'Welcome 👋' : 'Hi, $name 👋';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text('What would you like to do today?'),
      ],
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
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(icon,
              color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black54)),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
