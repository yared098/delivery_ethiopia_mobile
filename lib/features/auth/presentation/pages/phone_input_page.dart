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
  // No default value — user must type their own
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Normalizes to a 10-digit Ethiopian local number or returns null.
  String? _validatePhone(String? raw) {
    if (raw == null) return 'Enter your phone number';
    final digits = raw.replaceAll(RegExp(r'\D'), '');

    String normalized;
    if (digits.startsWith('251') && digits.length == 12) {
      normalized = digits.substring(3); // 9XXXXXXXX / 7XXXXXXXX
    } else if (digits.length == 10 &&
        (digits.startsWith('09') || digits.startsWith('07'))) {
      normalized = digits.substring(1); // 9XXXXXXXX / 7XXXXXXXX
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
    final phone = _controller.text.trim();
    context.read<AuthBloc>().add(RequestOtpEvent(phone));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deliver Ethiopia')),
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
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'Enter your phone number',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text('We will send you a one-time code via SMS.'),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _controller,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    autofocus: true,
                    enabled: !loading,
                    maxLength: 13,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]')),
                    ],
                    validator: _validatePhone,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      hintText: '0911223344',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 20),
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
                        : const Text('Send code'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
