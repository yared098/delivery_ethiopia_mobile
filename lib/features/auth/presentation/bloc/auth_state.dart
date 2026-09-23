import 'package:equatable/equatable.dart';
import '../../domain/entities/account.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

class OtpSent extends AuthState {
  const OtpSent(this.phone);
  final String phone;
  @override
  List<Object?> get props => [phone];
}

/// Verify passed but the phone is new — the UI must show the register form.
class RegistrationRequired extends AuthState {
  const RegistrationRequired({
    required this.registrationToken,
    required this.phone,
  });
  final String registrationToken;
  final String phone;
  @override
  List<Object?> get props => [registrationToken, phone];
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.account);
  final Account account;
  @override
  List<Object?> get props => [account];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
