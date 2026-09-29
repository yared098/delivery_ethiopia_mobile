import 'package:deliver_ethiopia/features/auth/domain/usecases/account_kind.dart';
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
  const AuthAuthenticated(
    this.account, [
    this.kind = AccountKind.customer,
  ]);
  final Account account;
  final AccountKind kind;

  @override
  List<Object?> get props => [account, kind];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
