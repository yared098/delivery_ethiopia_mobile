import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'register_customer_page.dart';

class OtpVerifyPage extends StatefulWidget {
  const OtpVerifyPage({super.key, required this.phone});
  final String phone;

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  final _code = TextEditingController();
  final _focus = FocusNode();

  static const _resendSeconds = 60;
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) t.cancel();
      });
    });
  }

  void _submit() {
    final code = _code.text.trim();
    if (code.length != 6) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Enter the 6-digit code'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
          VerifyOtpEvent(phone: widget.phone, code: code),
        );
  }

  void _resend() {
    if (_secondsLeft > 0) return;
    HapticFeedback.selectionClick();
    context.read<AuthBloc>().add(RequestOtpEvent(widget.phone));
    _code.clear();
    _focus.requestFocus();
    _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify your phone'),
        centerTitle: false,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          // ── 1. Existing user (or successful register) → Home ──
          if (state is AuthAuthenticated) {
            // Remove every pushed route so app.dart's HomePage becomes visible.
            if (!mounted) return;
            Navigator.of(context).popUntil((r) => r.isFirst);
            return;
          }

          // ── 2. New user → register page ──
          if (state is RegistrationRequired) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => RegisterCustomerPage(
                  registrationToken: state.registrationToken,
                  phone: state.phone,
                ),
              ),
            );
            return;
          }

          // ── 3. Resend confirmed ──
          if (state is OtpSent) {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
                const SnackBar(
                  content: Text('A new code has been sent'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            return;
          }

          // ── 4. Errors ──
          if (state is AuthError) {
            final msg = state.message.toLowerCase();
            final isDeadOtp = msg.contains('no active otp') ||
                msg.contains('otp expired') ||
                msg.contains('invalid otp');
            final isDisabled = msg.contains('disabled');

            if (isDeadOtp) {
              _code.clear();
              _focus.requestFocus();
              _startCooldown();
              HapticFeedback.mediumImpact();
            }

            // If the account is disabled, offer a way out
            if (isDisabled) {
              _showDisabledDialog(state.message);
              return;
            }

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
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(phone: widget.phone, scheme: scheme),
                      const SizedBox(height: 32),
                      _CodeInput(
                        controller: _code,
                        focusNode: _focus,
                        loading: loading,
                        onSubmit: _submit,
                        onChanged: () => setState(() {}),
                      ),
                      const SizedBox(height: 20),
                      _VerifyButton(
                        loading: loading,
                        enabled: _code.text.trim().length == 6,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 16),
                      _ResendRow(
                        secondsLeft: _secondsLeft,
                        loading: loading,
                        onResend: _resend,
                        onChangeNumber: () {
                          if (loading) return;
                          Navigator.of(context).pop();
                        },
                      ),
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

  Future<void> _showDisabledDialog(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Account disabled'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(_); // close dialog
              if (mounted) Navigator.of(context).pop(); // back to phone
            },
            child: const Text('Use another number'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Header
// ═══════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  const _Header({required this.phone, required this.scheme});
  final String phone;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.sms_outlined,
            size: 34,
            color: scheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Enter the 6-digit code',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'We sent a code to',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: scheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🇪🇹', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                phone,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Code input
// ═══════════════════════════════════════════════════════════════
class _CodeInput extends StatefulWidget {
  const _CodeInput({
    required this.controller,
    required this.focusNode,
    required this.loading,
    required this.onSubmit,
    required this.onChanged,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool loading;
  final VoidCallback onSubmit;
  final VoidCallback onChanged;

  @override
  State<_CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<_CodeInput> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
  }

  void _onText() {
    widget.onChanged();
    if (widget.controller.text.length == 6 && !widget.loading) {
      HapticFeedback.selectionClick();
      widget.onSubmit();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = widget.controller.text;
    final hasFocus = widget.focusNode.hasFocus;

    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            final filled = i < text.length;
            final isCurrent = hasFocus && i == text.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 46,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrent
                      ? scheme.primary
                      : filled
                          ? scheme.primary.withOpacity(0.4)
                          : Colors.transparent,
                  width: isCurrent ? 2 : 1.4,
                ),
              ),
              child: Text(
                filled ? text[i] : '',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            );
          }),
        ),
        Opacity(
          opacity: 0,
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            enabled: !widget.loading,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofocus: true,
            maxLength: 6,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onSubmitted: (_) => widget.onSubmit(),
            decoration: const InputDecoration(counterText: ''),
          ),
        ),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => widget.focusNode.requestFocus(),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Verify button
// ═══════════════════════════════════════════════════════════════
class _VerifyButton extends StatelessWidget {
  const _VerifyButton({
    required this.loading,
    required this.enabled,
    required this.onPressed,
  });
  final bool loading;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: (loading || !enabled) ? null : onPressed,
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
          : const Text('Verify'),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Resend + change number
// ═══════════════════════════════════════════════════════════════
class _ResendRow extends StatelessWidget {
  const _ResendRow({
    required this.secondsLeft,
    required this.loading,
    required this.onResend,
    required this.onChangeNumber,
  });
  final int secondsLeft;
  final bool loading;
  final VoidCallback onResend;
  final VoidCallback onChangeNumber;

  @override
  Widget build(BuildContext context) {
    final canResend = secondsLeft == 0 && !loading;
    return Column(
      children: [
        if (secondsLeft > 0)
          SizedBox(
            width: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (60 - secondsLeft) / 60,
                minHeight: 4,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: canResend ? onResend : null,
          child: Text(
            secondsLeft > 0
                ? 'Resend code in ${secondsLeft}s'
                : 'Resend code',
          ),
        ),
        TextButton(
          onPressed: loading ? null : onChangeNumber,
          child: const Text('Change phone number'),
        ),
      ],
    );
  }
}
