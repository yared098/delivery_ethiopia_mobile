import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      appBar: AppBar(title: const Text('Profile'), centerTitle: false),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: CircularProgressIndicator());
          }
          final account = state.account;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _Hero(account: account),
              const SizedBox(height: 20),
              _SectionTitle('Contact'),
              const SizedBox(height: 10),
              _GroupCard(
                children: [
                  _Row(
                    icon: Icons.person_outline,
                    label: 'Name',
                    value: account.name ?? 'Not set',
                  ),
                  _Row(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: account.phone,
                    onTap: () => _copy(
                      context,
                      account.phone,
                      'Phone copied',
                    ),
                  ),
                  _Row(
                    icon: Icons.mail_outline,
                    label: 'Email',
                    value: (account.email?.isNotEmpty ?? false)
                        ? account.email!
                        : 'Not set',
                    onTap: (account.email?.isNotEmpty ?? false)
                        ? () => _copy(context, account.email!, 'Email copied')
                        : null,
                  ),
                  _Row(
                    icon: Icons.location_on_outlined,
                    label: 'Default address',
                    value: (account.defaultAddress?.isNotEmpty ?? false)
                        ? account.defaultAddress!
                        : 'Not set',
                    onTap: (account.defaultAddress?.isNotEmpty ?? false)
                        ? () => _copy(context, account.defaultAddress!,
                            'Address copied')
                        : null,
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                onPressed: () => _openEditSheet(context, account),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit profile'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout),
                label: const Text('Log out'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Deliver Ethiopia · v1.0.0',
                  style: TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static void _copy(BuildContext context, String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(label),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        var saving = false;
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 4,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Edit profile',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: name,
                      enabled: !saving,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Full name *',
                        prefixIcon: Icon(Icons.person_outline),
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
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
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
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Default address',
                        prefixIcon: Icon(Icons.location_on_outlined),
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
                                defaultAddress:
                                    address.text.trim().isEmpty
                                        ? null
                                        : address.text.trim(),
                              );
                              if (!sheetCtx.mounted) return;
                              res.fold(
                                (f) {
                                  setState(() => saving = false);
                                  ScaffoldMessenger.of(sheetCtx)
                                      .showSnackBar(
                                    SnackBar(content: Text(f.message)),
                                  );
                                },
                                (updated) {
                                  Navigator.pop(sheetCtx);
                                  context
                                      .read<AuthBloc>()
                                      .add(const RefreshMeEvent());
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text('Profile updated'),
                                      behavior:
                                          SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              );
                            },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    name.dispose();
    email.dispose();
    address.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════
// Hero
// ═══════════════════════════════════════════════════════════════
class _Hero extends StatelessWidget {
  const _Hero({required this.account});
  final Account account;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = (account.name?.isNotEmpty ?? false)
        ? account.name!.trim()[0].toUpperCase()
        : '?';

    return Container(
      decoration: BoxDecoration(
        color: scheme.primary,
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
            radius: 32,
            backgroundColor: Colors.white.withOpacity(0.22),
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 26,
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
                  account.name ?? 'No name yet',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      account.phone,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (account.phoneVerified)
                      const Icon(
                        Icons.verified,
                        size: 14,
                        color: Colors.white,
                      ),
                  ],
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
// Grouped card + rows
// ═══════════════════════════════════════════════════════════════
class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(children: children),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.isLast = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 22, color: Colors.black54),
                const SizedBox(width: 14),
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
                if (onTap != null)
                  const Icon(Icons.copy, size: 16, color: Colors.black26),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 46, endIndent: 12),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      );
}
