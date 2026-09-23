import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'otp_verify_page.dart';

class PhoneInputPage extends StatefulWidget {
  const PhoneInputPage({super.key});
  static const routeName = '/login';

  @override
  State<PhoneInputPage> createState() => _PhoneInputPageState();
}

class _PhoneInputPageState extends State<PhoneInputPage> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  String? _validatePhone(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Enter your phone number';
    final digits = raw.replaceAll(RegExp(r'\D'), '');

    final String normalized;
    if (digits.startsWith('251') && digits.length == 12) {
      normalized = digits.substring(3);
    } else if (digits.length == 10 &&
        (digits.startsWith('09') || digits.startsWith('07'))) {
      normalized = digits.substring(1);
    } else if (digits.length == 9 &&
        (digits.startsWith('9') || digits.startsWith('7'))) {
      normalized = digits;
    } else {
      return 'Enter a valid Ethiopian number (e.g. 0911223344)';
    }

    if (!RegExp(r'^[97]\d{8}$').hasMatch(normalized)) {
      return 'Enter a valid Ethiopian number (e.g. 0911223344)';
    }
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(RequestOtpEvent(_controller.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is OtpSent) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OtpVerifyPage(phone: state.phone),
              ),
            );
          }
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      _Brand(scheme: scheme),
                      const SizedBox(height: 40),
                      _Heading(),
                      const SizedBox(height: 24),
                      _Form(
                        formKey: _formKey,
                        controller: _controller,
                        focusNode: _focus,
                        loading: loading,
                        onSubmit: _submit,
                        validate: _validatePhone,
                      ),
                      const SizedBox(height: 20),
                      _SubmitButton(
                        loading: loading,
                        onSubmit: _submit,
                      ),
                      const SizedBox(height: 24),
                      _LegalNote(),
                    ],
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

// ═══════════════════════════════════════════════════════════
// Brand header
// ═══════════════════════════════════════════════════════════
class _Brand extends StatelessWidget {
  const _Brand({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withOpacity(0.28),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Icon(
            Icons.local_shipping_rounded,
            color: scheme.onPrimary,
            size: 44,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Deliver Ethiopia',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Fast, safe delivery across Ethiopia',
          style: TextStyle(
            fontSize: 13,
            color: scheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Headline
// ═══════════════════════════════════════════════════════════
class _Heading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Sign in or create an account',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 6),
        Text(
          'Enter your phone number — we will send a 6-digit code via SMS.',
          style: TextStyle(fontSize: 13.5, color: Colors.black54),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Phone input form
// ═══════════════════════════════════════════════════════════
class _Form extends StatefulWidget {
  const _Form({
    required this.formKey,
    required this.controller,
    required this.focusNode,
    required this.loading,
    required this.onSubmit,
    required this.validate,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool loading;
  final VoidCallback onSubmit;
  final String? Function(String?) validate;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Form(
      key: widget.formKey,
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.done,
        autofocus: true,
        enabled: !widget.loading,
        maxLength: 13,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]')),
          LengthLimitingTextInputFormatter(13),
        ],
        validator: widget.validate,
        onFieldSubmitted: (_) => widget.onSubmit(),
        decoration: InputDecoration(
          labelText: 'Phone number',
          hintText: '0911223344',
          counterText: '',
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🇪🇹', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(
                  '+251',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withOpacity(0.75),
                  ),
                ),
                const SizedBox(width: 8),
                Container(width: 1, height: 22, color: scheme.outlineVariant),
              ],
            ),
          ),
          suffixIcon: widget.controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Clear',
                  onPressed: widget.loading
                      ? null
                      : () {
                          widget.controller.clear();
                          widget.focusNode.requestFocus();
                        },
                ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: scheme.primary, width: 1.6),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Submit button
// ═══════════════════════════════════════════════════════════
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.loading, required this.onSubmit});
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onSubmit,
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
              child: CircularProgressIndicator(strokeWidth: 2.4),
            )
          : const Text('Send code'),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Legal note
// ═══════════════════════════════════════════════════════════
class _LegalNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'By continuing you agree to our',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _link(context, 'Terms of Service'),
            Text(
              '  ·  ',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.35),
              ),
            ),
            _link(context, 'Privacy Policy'),
          ],
        ),
      ],
    );
  }

  Widget _link(BuildContext context, String text) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$text — coming soon'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
