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
  static const _resendSeconds = 60;
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) t.cancel();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _code.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit code')),
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
    context.read<AuthBloc>().add(RequestOtpEvent(widget.phone));
    _code.clear();
    _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          // ── 1. Existing user → home ──
          if (state is AuthAuthenticated) {
            Navigator.of(context).popUntil((r) => r.isFirst);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Welcome ${state.account.name ?? state.account.phone}',
                ),
              ),
            );
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('A new code has been sent')),
            );
            return;
          }

          // ── 4. Errors ──
          if (state is AuthError) {
            final msg = state.message.toLowerCase();
            final isDeadOtp = msg.contains('no active otp') ||
                              msg.contains('otp expired') ||
                              msg.contains('invalid otp');
            if (isDeadOtp) {
              _code.clear();
              _startCooldown();
            }
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
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.sms_outlined, size: 56),
                const SizedBox(height: 16),
                Text(
                  'Code sent to ${widget.phone}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: loading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Change number'),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofocus: true,
                  enabled: !loading,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    letterSpacing: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(),
                    hintText: '••••••',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: (_secondsLeft > 0 || loading) ? null : _resend,
                  child: Text(
                    _secondsLeft > 0
                        ? 'Resend code in ${_secondsLeft}s'
                        : 'Resend code',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
