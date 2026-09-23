import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class RequestOtpEvent extends AuthEvent {
  const RequestOtpEvent(this.phone);
  final String phone;
  @override
  List<Object?> get props => [phone];
}

class VerifyOtpEvent extends AuthEvent {
  const VerifyOtpEvent({required this.phone, required this.code});
  final String phone;
  final String code;
  @override
  List<Object?> get props => [phone, code];
}

class RegisterCustomerEvent extends AuthEvent {
  const RegisterCustomerEvent({
    required this.registrationToken,
    required this.name,
    this.email,
    this.defaultAddress,
    this.defaultLat,
    this.defaultLng,
  });
  final String registrationToken;
  final String name;
  final String? email;
  final String? defaultAddress;
  final double? defaultLat;
  final double? defaultLng;
  @override
  List<Object?> get props => [registrationToken, name];
}

class RefreshMeEvent extends AuthEvent {
  const RefreshMeEvent();
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}
