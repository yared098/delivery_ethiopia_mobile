import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterCustomerPage extends StatefulWidget {
  const RegisterCustomerPage({
    super.key,
    required this.registrationToken,
    required this.phone,
  });
  final String registrationToken;
  final String phone;

  @override
  State<RegisterCustomerPage> createState() => _RegisterCustomerPageState();
}

class _RegisterCustomerPageState extends State<RegisterCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _name.addListener(_rebuild);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();
    context.read<AuthBloc>().add(RegisterCustomerEvent(
          registrationToken: widget.registrationToken,
          name: _name.text.trim(),
          email: _email.text.trim().isEmpty ? null : _email.text.trim(),
          defaultAddress:
              _address.text.trim().isEmpty ? null : _address.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Complete your profile'),
        centerTitle: false,
        automaticallyImplyLeading: false,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          // 🔑 Success — pop to root so app.dart's HomePage is visible.
          if (state is AuthAuthenticated) {
            if (!mounted) return;
            Navigator.of(context).popUntil((r) => r.isFirst);
            return;
          }
          if (state is AuthError) {
            HapticFeedback.mediumImpact();
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                ),
              );
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Header(
                          phone: widget.phone,
                          name: _name.text.trim(),
                          scheme: scheme,
                        ),
                        const SizedBox(height: 28),
                        _FieldLabel('Your details'),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _name,
                          autofocus: true,
                          enabled: !loading,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Full name *',
                            hintText: 'Almaz Tesfaye',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().length < 2)
                                  ? 'Enter your full name'
                                  : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _email,
                          enabled: !loading,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Email (optional)',
                            hintText: 'you@example.com',
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
                        const SizedBox(height: 24),
                        _FieldLabel('Default address'),
                        const SizedBox(height: 4),
                        Text(
                          'Optional — used to pre-fill new orders.',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurface.withOpacity(0.55),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _address,
                          enabled: !loading,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          minLines: 1,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Default address (optional)',
                            hintText: 'Bole, Addis Ababa',
                            prefixIcon: Icon(Icons.location_on_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 32),
                        FilledButton(
                          onPressed: loading ? null : _submit,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.4),
                                )
                              : const Text('Create account'),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'You can change these later in Profile.',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurface.withOpacity(0.55),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Header
// ═══════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  const _Header({
    required this.phone,
    required this.name,
    required this.scheme,
  });
  final String phone;
  final String name;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Column(
      children: [
        const SizedBox(height: 12),
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surface, width: 3),
              ),
              child: Icon(
                Icons.check,
                size: 16,
                color: scheme.onPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Almost there!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Finish creating your Deliver Ethiopia account.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            color: scheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🇪🇹', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                phone,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.verified, size: 16, color: scheme.primary),
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
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
