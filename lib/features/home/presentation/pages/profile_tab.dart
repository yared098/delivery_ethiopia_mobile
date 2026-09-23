import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../di/service_locator.dart';
import '../../../auth/domain/entities/account.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../profile/domain/usecases/update_profile.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: CircularProgressIndicator());
          }
          final account = state.account;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _Header(account: account),
              const SizedBox(height: 24),
              _Row(
                icon: Icons.person_outline,
                label: 'Name',
                value: account.name ?? 'Not set',
              ),
              _Row(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: account.phone,
              ),
              _Row(
                icon: Icons.mail_outline,
                label: 'Email',
                value: (account.email?.isNotEmpty ?? false)
                    ? account.email!
                    : 'Not set',
              ),
              _Row(
                icon: Icons.location_on_outlined,
                label: 'Default address',
                value: (account.defaultAddress?.isNotEmpty ?? false)
                    ? account.defaultAddress!
                    : 'Not set',
              ),
              const SizedBox(height: 32),
              FilledButton.tonalIcon(
                onPressed: () => _openEditSheet(context, account),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit profile'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout),
                label: const Text('Log out'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to verify your phone again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<AuthBloc>().add(const LogoutEvent());
    }
  }

  Future<void> _openEditSheet(BuildContext context, Account account) async {
    final name = TextEditingController(text: account.name ?? '');
    final email = TextEditingController(text: account.email ?? '');
    final address = TextEditingController(text: account.defaultAddress ?? '');
    final formKey = GlobalKey<FormState>();
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (ctx, setState) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Edit profile',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: name,
                      enabled: !saving,
                      decoration: const InputDecoration(
                        labelText: 'Full name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().length < 2)
                          ? 'Enter your full name'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: email,
                      enabled: !saving,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(v)
                            ? null
                            : 'Enter a valid email';
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: address,
                      enabled: !saving,
                      decoration: const InputDecoration(
                        labelText: 'Default address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (!(formKey.currentState?.validate() ??
                                  false)) {
                                return;
                              }
                              setState(() => saving = true);
                              final res = await sl<UpdateProfile>()(
                                name: name.text.trim(),
                                email: email.text.trim().isEmpty
                                    ? null
                                    : email.text.trim(),
                                defaultAddress: address.text.trim().isEmpty
                                    ? null
                                    : address.text.trim(),
                              );
                              if (!sheetCtx.mounted) return;
                              res.fold(
                                (f) {
                                  setState(() => saving = false);
                                  ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                    SnackBar(content: Text(f.message)),
                                  );
                                },
                                (updated) {
                                  Navigator.pop(sheetCtx);
                                  // Refresh so the app shell shows the new data
                                  context
                                      .read<AuthBloc>()
                                      .add(const RefreshMeEvent());
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Profile updated'),
                                    ),
                                  );
                                },
                              );
                            },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    name.dispose();
    email.dispose();
    address.dispose();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.account});
  final Account account;

  @override
  Widget build(BuildContext context) {
    final initial = (account.name?.isNotEmpty ?? false)
        ? account.name!.trim()[0].toUpperCase()
        : '?';
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.name ?? 'No name yet',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                account.phone,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16)),
    );
  }
}
